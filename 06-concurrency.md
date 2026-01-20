# Processes and Concurrency

Inko uses lightweight processes for safe, efficient concurrency. The model is inspired by Erlang and Pony.

## Lightweight Processes

Processes are **isolated** and **communicate via messages**:

```inko
import std.sync (Promise)

type async Counter {
  let mut @value: Int

  fn async pub mut increment {
    @value = @value + 1
  }

  fn async pub get(promise: uni Promise[Int]) {
    promise.set(@value)
  }
}

type async Main {
  fn async main {
    let counter = Counter(value: 0)
    counter.increment
    counter.increment
    let result = await counter.get  # => 2
  }
}
```

**Key characteristics:**

- Each `type async` instance spawns a new process
- Processes don't share memory
- Data races are impossible by design
- Multiple processes can run in parallel

## Process Isolation

Processes are isolated through Inko's ownership system:

```inko
# Values are MOVED to processes, not copied
let data = [1, 2, 3]
process.send(data)  # data is moved, no longer accessible here
```

**Only sendable types can cross process boundaries:**

- Unique values (`uni T`)
- Value types (`Int`, `Float`, `Bool`, `String`)
- Owned types containing only sendable subtypes

**This prevents:**

- Data races
- Use-after-free
- Iterator invalidation
- Shared mutable state

## Async Methods

Define async methods callable from other processes:

```inko
type async Database {
  let @connections: Array[Connection]

  fn async pub query(sql: String) -> Result[Rows, Error] {
    # Execute query
  }

  fn async pub mut close {
    # Close connections
  }
}
```

**Calling async methods:**

```inko
# From another process
let db = Database()
let rows = await db.query("SELECT * FROM users")
```

## Scheduling and Parallelism

**Preemptive multitasking:**

- Inko uses a fixed-size pool of OS threads
- N threads -> N processes run in parallel
- Preemptive scheduling prevents any process from blocking threads indefinitely

**Unlike cooperative systems:**

- No "infinite loop blocks everything" problem
- Fair scheduling across processes
- Predictable latency characteristics

## Message Passing with Promises

Use `Promise` for synchronous request-response:

```inko
import std.sync (Promise)

type async Worker {
  fn async pub factorial(n: Int, promise: uni Promise[Int]) {
    let result = calculate_factorial(n)
    promise.set(result)
  }
}

type async Main {
  fn async main {
    let worker = Worker()
    let result = await worker.factorial(10)  # Waits for response
    # result = 3628800
  }
}
```

## Concurrency Patterns

**Fan-out pattern:**

```inko
let workers = [Worker(), Worker(), Worker()]

for worker in workers {
  worker.process_task(task)
}
```

**Pipeline pattern:**

```inko
let stage1 = Stage1()
let stage2 = Stage2()
let stage3 = Stage3()

# Data flows through stages
stage1.process(data)  # Sends to stage2
# stage2 sends to stage3
# stage3 produces final result
```

## Performance Characteristics

- Process creation: Very lightweight (thousands possible)
- Message passing: Zero-copy (values are moved)
- Context switching: Managed by Inko runtime, not OS
- Parallelism: Limited by thread pool size

## Differences from Other Models

**vs. Erlang:**

- No copying on message send (move semantics)
- Predictable memory usage (no GC)
- Static typing catches errors at compile time

**vs. Go:**

- No shared memory between processes
- Data races impossible by design
- No need for mutexes or channels

**vs. Rust async:**

- Simpler programming model
- No Pin/Unpin complexity
- Runtime-managed scheduling

---

## Async/Await

Inko 0.19.1 reintroduces async/await as syntax sugar for working with `Future` and `Promise` types.

### Async Functions

```inko
type async Main {
  fn async main {
    let result = async_operation
    # Process result
  }
}
```

### Async Methods

```inko
impl MyType {
  fn pub async fetch_data -> Result[String, String] {
    # Async operation
    Result.Ok("data")
  }
}
```

**Key points:**

- Use `type async` for async types
- Use `fn async` for async methods
- Async/await reduces boilerplate when spawning processes
- Works with `Future` and `Promise` types from the standard library
