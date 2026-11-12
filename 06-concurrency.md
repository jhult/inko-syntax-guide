# Processes and Concurrency

Inko uses lightweight processes for safe, efficient concurrency. The model is
inspired by Erlang and Pony: processes are isolated, and data crosses process
boundaries by being moved rather than shared mutably.

## Lightweight Processes

Processes are defined with `type async`. Each instance is a process, and
interacting with it means sending it a message (calling an `fn async` method):

```inko
import std.sync (Promise)

type async Counter {
  let mut @value: Int

  fn pub async mut increment {
    @value = @value + 1
  }

  fn pub async get(promise: uni Promise[Int]) {
    promise.set(@value)
  }
}

type async Main {
  fn async main {
    let counter = Counter(value: 0)

    counter.increment
    counter.increment

    let result = await counter.get # => 2
  }
}
```

**Key characteristics:**

- Each `type async` instance runs as its own process
- Processes don't share mutable memory
- Data races are impossible by design
- Processes run in parallel on a fixed-size pool of OS threads
- Messages to a single process are handled one at a time, in FIFO order

## Process Isolation and Sendability

Values cross process boundaries by being moved or copied. A value is
**sendable** if it is:

- A value type: `Int`, `Float`, `Bool`, `Nil`, `String`, a process handle, or a
  `type ref` value
- A unique value: `uni T` (e.g. `uni Array[Int]`, `uni ByteArray`)

Mutable borrows are never sendable, and immutable `ref T` borrows are not
sendable across processes either. This is what prevents:

- Data races
- Use-after-free
- Iterator invalidation
- Shared mutable state

Create a unique value with `recover`, which flips `T` to `uni T` (and `uni T`
back to `T`):

```inko
let data = recover [10, 20] # => uni Array[Int]
worker.consume(data)        # ownership moves to the worker
```

Unique values are covered in more detail in
[19-shared-state.md](19-shared-state.md).

## Async Methods

Use `fn pub async` (optionally `fn pub async mut`) for messages. Note the order
of the modifiers: `pub` comes **before** `async`.

```inko
type async Database {
  fn pub async query(promise: uni Promise[Rows], sql: String) {
    # Execute query, then send the result back through the promise
    promise.set(rows)
  }

  fn pub async mut close {
    # Close connections
  }
}
```

**Important:** async methods cannot declare a return type. To return a value,
accept a `uni Promise[T]` and resolve it. The `await` expression creates the
promise for you and returns the resolved value, which is why the promise must be
the method's **first argument**:

```inko
type async Main {
  fn async main {
    let db = Database()
    let rows = await db.query('SELECT * FROM users')
  }
}
```

Calling an async method works in three ways:

```inko
# Fire and forget (only for methods that don't take a Promise)
worker.notify

# Wait for the result
let value = await worker.compute(10)

# Start the work, keep going, resolve later
let future = async worker.compute(10)
# ... do other work ...
let value = future.get
```

If an async method takes a `Promise` and you don't care about the result, still
use `async` and discard the returned `Future`:

```inko
let _ = async worker.compute(10)
```

## Futures and Promises

`Future` and `Promise` are the primitives behind `async` and `await`. A
`Future` is a proxy for a value to be computed, and a `Promise` resolves it:

```inko
import std.sync (Future, Promise)

type async Printer {
  fn pub async print(promise: uni Promise[Nil], message: String) {
    # Produce the output
    promise.set(nil)
  }
}

type async Main {
  fn async main {
    let printer = Printer()

    let (future, promise) = Future.new
    printer.print(promise, 'hello')

    future.get # Blocks until the promise is resolved
  }
}
```

`await` is sugar for this pattern:

```inko
# This:
let value = await worker.compute(10)

# Compiles to:
let (future, promise) = Future.new
worker.compute(promise, 10)
let value = future.get
```

Useful `Future` methods:

- `get` — block until resolved, returning the value
- `try_get` — return `Result.Ok(value)` if resolved, otherwise the `Future`
- `get_until(deadline)` — block until resolved or the deadline expires

## Scheduling and Parallelism

Inko schedules processes onto a fixed-size pool of OS threads, with the default
size derived from the number of CPU cores. Set `INKO_PROCESS_THREADS` (1-65535)
to override it. Work stealing is used: each thread has a bounded local queue,
and idle threads steal work from others.

**Cooperative, not preemptive:**

- The compiler inserts *preemption points* that periodically yield back to the
  scheduler
- Processes get roughly a 10 ms time slice, which prevents an infinite loop from
  starving everything else
- Blocking operations (`await`, socket reads) suspend the process rather than
  the OS thread

**Practical implications:**

- N threads means at most N processes execute at the same time
- A process that never reaches a preemption point (e.g. a long FFI call) can
  hold onto a thread
- Throughput of one process is limited to one core; parallelism comes from
  using multiple processes

## Concurrency Patterns

**Fan-out:**

```inko
let workers = [Worker(), Worker(), Worker()]

for worker in workers.iter {
  worker.process_task
}
```

**Pipeline:**

```inko
let stage1 = Stage1()
let stage2 = Stage2()
let stage3 = Stage3()

# Data flows through stages via messages
stage1.process(data, stage2)
# stage2 processes and forwards to stage3
```

**Work queue:**

`std.sync.Channel` is an unbounded multiple-producer/multiple-consumer queue:

```inko
import std.sync (Channel)

let jobs: Channel[uni Job] = Channel.new
jobs.send(recover Job.new)

let job = jobs.receive
```

## Sharing State Across Processes

Because processes don't share memory, "share one object across connections" is
not a matter of wrapping it in a lock. The available mechanisms are:

- A process that owns the object (actor)
- Moving a `uni T` between processes
- Immutable shared data with `type ref`
- Shared counters/flags with `AtomicInt` and `AtomicBool`
- Pools and queues with `Channel`

There is no public `Mutex[T]`/`RwLock[T]`. See
[19-shared-state.md](19-shared-state.md) for examples, costs and guidance.

## Performance Characteristics

- Process creation is cheap: a process is a heap value plus a scheduler entry
- Value types are copied when sent; `String` is atomically reference counted, so
  copies are cheap
- `uni T` values are moved without copying
- Each request/response allocates a `Future`/`Promise`
- One process runs on one core at a time
- Memory is managed by ownership, not a garbage collector

## Differences from Other Models

**vs. Erlang:**

- No copying when moving unique values
- No GC; predictable memory usage
- Static typing catches more errors at compile time

**vs. Go:**

- No shared memory between processes
- Data races are impossible by design
- Channels exist, but there are no mutexes to reach for

**vs. Rust async:**

- Simpler programming model (no `Pin`/`Unpin`)
- Runtime-managed scheduling
- `uni T` is roughly Pony's `iso`, not Rust's `Send`/`Sync` split

**vs. Pony:**

- Inko's `uni T` corresponds to Pony's `iso`
- Reference capabilities are otherwise much less granular
