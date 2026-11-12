# Sharing State Across Processes

> Applies to Inko 0.21.1. Read [06-concurrency.md](06-concurrency.md) first for
> the basics of processes, `async`/`await` and `Promise`.

Inko processes never share mutable memory. If several connections, requests or
workers need access to "the same thing", you have to choose one of the
mechanisms below. There is no `Arc<Mutex<T>>` equivalent in Inko.

| Need | Mechanism | Cost |
|------|-----------|------|
| One mutable owner, many callers | A process (`type async`) | One message + future per call; serialized |
| Hand state between processes | `uni T` + `recover` | Zero-copy move, but exclusive |
| Read-only data shared by everyone | `type ref` | Cheap reference count bump |
| Shared counters/flags | `AtomicInt` / `AtomicBool` | Atomic operations |
| Pool of reusable values | `std.sync.Channel` | Message + future per send/receive |
| General-purpose mutex | **Not available** | Use a process instead |

## 1. A process owns the state (actor)

The native mechanism is a process that owns the mutable value. Messages to that
process are executed one at a time, so the state needs no locking:

```inko
import std.sync (Promise)

type async Scanner {
  let mut @count: Int

  fn pub async mut scan(promise: uni Promise[Int], input: String) {
    @count = @count + input.size
    promise.set(@count)
  }
}
```

The `Promise` is what lets the caller get a result back: async methods can't
return values. The `await` expression supplies the `Promise` for you, which is
why it must be the **first** argument:

```inko
type async Main {
  fn async main {
    let scanner = Scanner(count: 0)

    let a = await scanner.scan('hello') # => 5
    let b = await scanner.scan('!')     # => 6
  }
}
```

### Sharing the process handle

Processes are value types that use atomic reference counting (see the Inko
manual's concurrency guide), so a handle can be passed to any number of other
processes. Every copy refers to the same process:

```inko
type async Connection {
  let @scanner: Scanner

  fn pub async mut run(promise: uni Promise[Int], input: String) {
    promise.set(await @scanner.scan(input))
  }
}

let scanner = Scanner(count: 0)

let _ = async Connection(scanner: scanner).run('a')
let _ = async Connection(scanner: scanner).run('b')
```

Both connections send messages to the same `Scanner`, and its `scan` method is
executed one call at a time.

### Rules and costs

- Async methods have **no return type**; use a `Promise`, `await`, or a
  `Channel`.
- Arguments must be **sendable**, as must values returned through the promise.
- A result that borrows the input (e.g. a `Slice[String]` into the request
  buffer) is **not sendable**. Return owned data, or return offsets/lengths.
- Each call allocates a `Future`/`Promise`, enqueues a message and (with
  `await`) waits for a scheduling round-trip. One process also runs on one core
  at a time, so a single shared process serializes all work.
- Process messages are FIFO, which makes this a good fit for state that must be
  globally ordered (statistics, connection registries), and a poor fit for hot
  per-request parsing.

## 2. Move ownership with `uni` and `recover`

If only one process needs the value at a time, move it instead of sharing it.
`recover` converts between an owned `T` and a unique `uni T`, and back:

```inko
type pub Scanner {
  let mut @pos: Int

  fn pub static new -> Scanner {
    Scanner(pos: 0)
  }

  fn pub mut scan(input: String) -> Int {
    @pos = @pos + input.size
    @pos
  }
}

type async Worker {
  fn pub async mut use(promise: uni Promise[uni Scanner], scanner: uni Scanner) {
    promise.set(scanner)
  }
}

let scanner = Scanner.new
let unique = recover scanner       # Scanner -> uni Scanner
let mut back = await Worker().use(unique) # uni Scanner again
let _ = back.scan('abc')
```

Key points:

- `recover value` flips the type: `T` becomes `uni T`, `uni T` becomes `T`.
  You only wrap once to make a value sendable. Sending a value that is already
  `uni T` needs no second `recover`.
- A `uni T` can be passed to a process and stored in its fields.
- Methods callable on a `uni T` must only accept and return sendable values.
- `ref T` and `mut T` borrows are **not** sendable, so you cannot share a
  borrowed `Scanner` across processes.
- Moving is zero-copy and ideal for checkout/return schemes (lending a parser to
  a worker and getting it back).

## 3. Read-only shared data: `type ref`

`type ref` values are heap allocated, atomically reference counted and treated
as value types. Assignment copies the reference, not the data, and the value can
be sent to any process without copying:

```inko
type pub ref Config {
  let @name: String

  fn pub static new(name: String) -> Config {
    Config(name: name)
  }

  fn pub matches?(input: String) -> Bool {
    input == @name
  }
}

type async Worker {
  let @config: Config

  fn pub async mut check(promise: uni Promise[Bool], input: String) {
    promise.set(@config.matches?(input))
  }
}

let config = Config.new('abc')
let ok = await Worker(config: config).check('abc')
```

Restrictions (see the Inko manual's types guide):

- Fields cannot be assigned new values and there are no mutating methods.
- Fields may only be `copy` or `ref` types.
- The destructor runs when the last reference is dropped.

Use `type ref` for the **immutable** part of a shared object: configuration,
limits, precomputed tables, keyword sets, routes. You cannot put a mutable
cursor/parser state in one.

### Recommended split

For a stateful parser, the idiomatic design is:

1. Immutable, expensive setup in a `type ref` value, constructed once.
2. A small per-connection cursor struct that owns its mutable state and holds a
   `ref` to the shared setup.

Every connection gets the shared setup by copying a reference; there is no
contention and no locking.

## 4. Shared mutable counters and flags: atomics

`std.sync` exposes two mutable shared primitives: `AtomicInt` and `AtomicBool`.
They are `type ref` values, so they are sendable and share their underlying
storage. A `type ref` may hold and expose them, even though its own fields are
immutable:

```inko
import std.sync (AtomicInt, Promise)

type pub ref Stats {
  let @parsed: AtomicInt

  fn pub static new -> Stats {
    Stats(parsed: AtomicInt.new(0))
  }

  fn pub bump -> Int {
    @parsed.add(1)
  }

  fn pub count -> Int {
    @parsed.load
  }
}

type async Recorder {
  let @stats: Stats

  fn pub async mut record(promise: uni Promise[Nil]) {
    let _ = @stats.bump
    promise.set(nil)
  }
}

let stats = Stats.new

await Recorder(stats: stats).record
await Recorder(stats: stats).record

stats.count # => 2
```

`AtomicInt` also provides `compare_and_swap`, `store`, `add` and `sub`.
`AtomicBool` provides `compare_and_swap`, `store` and `load`. Both use acquire
semantics for loads and release semantics for stores.

### The `type inline` + `Clone` variant

Inko's standard library uses a different spelling for its HTTP server state
(`std/src/std/net/http/server.inko:1796`): a `type inline` struct holding
atomics, with an explicit `Clone` implementation that copies the atomic handles,
recovered when sent:

```inko
import std.clone (Clone)
import std.sync (AtomicInt)

type inline SharedStats {
  let @parsed: AtomicInt

  fn pub static new -> SharedStats {
    SharedStats(parsed: AtomicInt.new(0))
  }
}

impl Clone for SharedStats {
  fn pub clone -> Self {
    Self(parsed: @parsed)
  }
}

let stats = SharedStats.new
await Recorder(stats: recover stats.clone).record
```

Both variants work. Prefer `type ref` unless you have a reason to use
`type inline`.

### There is no public `Mutex[T]` / `RwLock[T]`

The only locking primitive in the standard library is a private spinlock used by
`Future` (`std/src/std/sync.inko:118-198`, types `Lock` and `Shared`). It sits
on top of manually allocated memory and raw pointers and is not exposed. If you need a
general mutable value shared across processes, put it in a process (section 1).
Do not hand-roll a `Mutex` around `AtomicBool` + `Pointer[T]` unless you are
prepared to deal with manual allocation, `Drop`, and the scheduler's spin
behavior.

## 5. Channels: pools and work queues

`std.sync.Channel[T]` is an unbounded multiple-producer/multiple-consumer FIFO
queue. `send` never blocks; `receive` blocks until a value is available;
`receive_until` waits until a deadline. There is **no** `try_receive` — the
shared state is itself a process, so a non-blocking check would race with the
message that resolves it.

A channel is a good way to reuse a fixed number of expensive values:

```inko
import std.sync (Channel)

let pool: Channel[uni Scanner] = Channel.new

# Construct the scanners once
pool.send(recover Scanner.new)
pool.send(recover Scanner.new)

# In each connection: check one out, use it, return it
let mut scanner = pool.receive
let pos = scanner.scan('xy')
pool.send(scanner)
```

Notes:

- Values are moved in and out, so the channel is a **checkout** mechanism, not
  shared mutation. Only one process uses a scanner at a time.
- `Channel` implements `Clone`, and clones share the same underlying state. To
  give the channel to a process, use `recover channel.clone`.
- Sending a `uni T` through a channel does not wrap it again: `send` accepts
  `uni T` directly.
- If you need a value within a bounded time, use `receive_until` with a
  `Duration`.

## 6. Choosing a design

| Situation | Use |
|-----------|-----|
| One logically single mutable object, many callers | Process owning the object |
| Expensive to construct, exclusive per request | `Channel` pool of `uni T` |
| Expensive to construct, mostly immutable | `type ref` shared config |
| Shared counters / flags / shutdown state | `AtomicInt` / `AtomicBool` |
| Handing a value to a worker and back | `uni T` + `recover` |
| Need a lock around arbitrary `T` | Not supported; use a process |

## 7. Applying this to a Scanner

A common suggestion is "construct one Scanner and share it across connections
via a process, or via an explicit shared state type". In Inko:

- **Process**: works and is safe, but serializes every parse and adds a
  future/message round-trip per scan. `await` cannot return borrowed slices, so
  parsed headers must be copied or expressed as offsets. This is usually the
  wrong default for a hot parser.
- **`type ref` shared state**: cannot hold mutable cursor state, so it only
  works for the immutable half (tables, keyword maps, limits).
- **Channel pool**: a good fit when construction is expensive and each
  connection needs exclusive use of a scanner for the duration of a request.
- **Split design**: usually the best answer — shared immutable setup in a
  `type ref`, per-connection scanner state owned by the connection.
- **Per-connection construction**: if construction is cheap, just build one per
  connection. `std`'s HTTP server deliberately creates a handler per connection
  rather than sharing one (`std/src/std/net/http/server.inko:2753`).

## 8. Caveats checklist

- Async methods cannot declare a return type; use `Promise` + `await`.
- `await` requires the `Promise` to be the method's first argument.
- Async method arguments must be sendable (value types, process handles, or
  `uni T`).
- `ref T` / `mut T` borrows are never sendable.
- `recover` flips uniqueness; don't double-wrap.
- `uni` receivers only allow methods whose arguments and returns are sendable.
- `type ref` values are immutable; only `AtomicInt`/`AtomicBool` support
  interior mutation in `std`.
- A single process executes messages one at a time, on one core.
