# Type Definitions and Memory Management

## Basic Type

```inko
type pub Person {
  let @name: String
  let @age: Int
  let mut @email: String
}
```

**Key points:**

- Use `type pub` for public types (NOT `class`)
- Use `let @field` for immutable fields
- Use `let mut @field` for mutable fields
- Fields are always prefixed with `@`

## Constructor

```inko
impl Person {
  fn pub static new(name: String, age: Int) -> Person {
    Person(
      name: name,
      age: age,
      email: "",
    )
  }
}
```

**Key points:**

- Constructors are `fn pub static new`
- Return the type with named fields (like struct initialization)
- Field order doesn't matter when using named parameters

## Generic Type

```inko
type pub HashMap[K, V] {
  let @buckets: Array[Array[(K, V)]]
  let @size: Int
}

impl HashMap[K, V] {
  fn pub static new -> HashMap[K, V] {
    HashMap(
      buckets: [],
      size: 0,
    )
  }
}
```

**Key points:**

- Use square brackets for type parameters: `[K, V]`
- Generic types are specialized at compile time for better performance

---

## Type Modifiers

Inko provides six distinct type definition modifiers, each optimized for different use cases.

### Regular `type` (Heap-Allocated)

Standard types allocated on the heap and accessed through pointers.

```inko
type pub User {
  let @name: String
  let @posts: Array[Post]
}
```

**When to use:**

- Complex objects with many heap-allocated values (8+ fields)
- Large types (128+ bytes)
- Recursive structures
- Types that need trait casting
- Types requiring in-place mutation

### `type inline` (Stack-Allocated)

Stack-allocated types that copy data when borrowed.

```inko
type inline pub Point {
  let @x: Int
  let @y: Int
}
```

**Key characteristics:**

- Reduces heap allocations
- Fields only assignable through owned references
- Each borrowed heap value increments borrow count

**Limitations:**

- Cannot be recursive
- Cannot cast to traits
- Higher stack consumption

**When to use:**

- Small types with few fields
- Types mixing value and heap types
- When you need mutability but want stack allocation

### `type copy` (Immutable Value Types)

Stack-allocated immutable types that copy on moves, like primitives.

```inko
type copy pub Color {
  let @r: Int
  let @g: Int
  let @b: Int
}
```

**Constraints:**

- May only contain `Int`, `Float`, `Bool`, `Nil`, or other `copy` types
- **Cannot** contain `String` (uses atomic reference counting)
- Completely immutable - no `fn mut` methods
- Cannot implement `Drop` trait
- Cannot cast to traits

**When to use:**

- Types containing only primitive values
- No mutation needed
- Maximum performance for small value types

### `type ref` (Atomically Reference-Counted Types) — NEW in 0.20.0

Atomically reference-counted types that behave as value types. Multiple owners can read fields simultaneously.

```inko
type ref pub SharedConfig {
  let @name: String
  let @version: Int
}
```

**Key characteristics:**

- Use atomic reference counting (thread-safe shared ownership)
- Considered value types — `let b = a` copies the reference, both can read
- **Immutable** — cannot assign fields new values or mutate in-place
- May only store other `ref` or `copy` types (e.g., `Int`, `String`)

**When to use:**

- Shared immutable data that multiple processes need to read
- Data that needs to cross process boundaries without copying
- Replacement for `type copy` when `String` fields are needed (since `type copy` cannot contain `String`)

### `type enum` (Algebraic Data Types)

Enum classes support variants with or without associated data.

```inko
type enum pub Result[T, E] {
  case Ok(T)
  case Error(E)
}

type enum pub Option[T] {
  case Some(T)
  case None
}
```

**Can be combined with modifiers:**

```inko
# Heap-allocated enum (default)
type enum Status {
  case Active
  case Inactive
}

# Stack-allocated enum
type inline enum SmallEnum {
  case A
  case B
}

# Immutable value enum
type copy enum Direction {
  case Up
  case Down
  case Left
  case Right
}
```

**Performance:** Matching against enum variants uses jump tables (O(1) performance).

### `type async` (Process Types)

Process types spawn lightweight concurrent processes.

```inko
type async pub Worker {
  let @id: Int
  let mut @tasks: Int
}

impl Worker {
  fn async pub mut process_task {
    @tasks = @tasks + 1
  }
}
```

**Key points:**

- Each instance spawns a new process
- Processes are isolated and communicate via messages
- Can define async methods callable from other processes

### Decision Framework

**Use this evaluation sequence:**

1. Need mutation in-place, recursion, many heap values (8+), size 128+ bytes, or trait casting?
   -> Use regular `type`

2. Shared immutable data with `String` fields that multiple processes need to read?
   -> Use `type ref`

3. Only storing primitive `copy` types (`Int`, `Float`, `Bool`) without mutation?
   -> Use `type copy`

4. All other cases (small types, mixed value/heap types, need some mutability)?
   -> Use `type inline`

5. Algebraic data types?
   -> Use `type enum` (optionally with `inline` or `copy`)

6. Concurrent processes?
   -> Use `type async`

---

## Memory Management

Inko uses automatic memory management without garbage collection, based on **single ownership** and **move semantics**.

### Single Ownership

Each value has exactly one owner. When the owner is done with the value, it's automatically dropped.

```inko
let val = "hello"
let vals = [val]  # Array now owns the value
# val is no longer accessible here - compile error if used
```

### Move Semantics

Values are **moved** by default (ownership transfer):

```inko
let a = [1, 2, 3]
let b = a  # Ownership moves to b
# a is no longer valid here
```

**Value types** (Int, Float, Bool, String) are **copied** automatically on move:

```inko
let x = 42
let y = x  # x is copied, both x and y are valid
```

### References: Borrowing Without Ownership

Inko supports three reference types:

#### Immutable References (`ref T`)

Read-only access without ownership transfer:

```inko
fn print_length(text: ref String) {
  # Can read but not modify
  text.size
}

let msg = "hello"
print_length(ref msg)  # msg is still owned by this scope
```

#### Mutable References (`mut T`)

Modify access without ownership transfer:

```inko
fn increment(value: mut Int) {
  # Can modify through the reference
}

let mut count = 0
increment(mut count)
```

#### Unique References (`uni T`)

Unique values restrict external references, enabling safe concurrency:

```inko
# recover creates unique values
let c = recover [10, 20]  # c is uni Array[Int]

# Unique values can be safely sent between processes
process.send(c)
```

**Key point:** Only unique values or value types can cross process boundaries.

### Key Differences from Rust

**Inko is more forgiving than Rust:**

1. **Multiple borrows allowed:** Both mutable and immutable references can coexist
2. **Can move while borrowed:** Owned values can be moved even when references exist
3. **Runtime checking:** Instead of compile-time errors, Inko panics at runtime if you access a reference after the value is dropped

**This enables:**

- Self-referential structures (doubly-linked lists) without unsafe code
- More flexibility in data structure design
- Simpler mental model, but with runtime cost

### Common Ownership Patterns

**Pattern 0: Implementing `Clone` for custom types**

When you need to get owned copies from `ref T` references (e.g., from `Array.get`), your type must implement the `Clone` trait. This is especially important for `type inline` enums containing non-value types like `String` or `Array`.

```inko
import std.clone (Clone)

type inline pub Color {
  let @name: String
  let @rgb: Array[Int]
}

impl Clone for Color {
  fn pub clone -> Self {
    Color(name: @name.clone, rgb: @rgb.clone)
  }
}
```

For `type enum` with variants containing heap data:

```inko
import std.clone (Clone)

type inline enum pub JsonValue {
  case Null
  case Boolean(Bool)
  case Number(String)
  case String(String)
  case Array(Array[JsonValue])
  case Object(Array[(String, JsonValue)])
}

impl Clone for JsonValue {
  fn pub clone -> Self {
    match self {
      case Null -> JsonValue.Null
      case Boolean(b) -> JsonValue.Boolean(b)
      case Number(n) -> JsonValue.Number(n.clone)
      case String(s) -> JsonValue.String(s.clone)
      case Array(a) -> JsonValue.Array(a.clone)
      case Object(o) -> JsonValue.Object(o.clone)
    }
  }
}
```

**Key points:**

- `type copy` types automatically copy — no `Clone` implementation needed
- `type inline` and regular `type` need `impl Clone for X` if you need `.clone`
- Value type fields (`Int`, `Float`, `Bool`, `String`) copy automatically inside the clone method
- Non-value type fields (`Array`, custom types) need `.clone` in the implementation
- `Bool` is a value type — no `.clone` needed for boolean fields

**Pattern 1: Borrow for reading, keep for later**

```inko
fn process_data(data: ref Array[Int]) -> Int {
  data.size
}

let items = [1, 2, 3]
let count = process_data(items)
# items still usable here because we passed ref
items.push(4)
```

**Pattern 2: Transfer ownership to function**

```inko
fn consume_data(data: Array[Int]) {
  # data is dropped after this function
}

let items = [1, 2, 3]
consume_data(items)
# items is moved, can't use here
```

**Pattern 3: Unique values for concurrency**

```inko
let unique_data = recover [1, 2, 3]
# Can safely send unique_data between processes
# Compiler prevents creating borrows that could cause races
```

**Pattern 4: `@field` access in `fn mut` methods returns `mut T`**

Inside a `fn mut` method, accessing `@field` yields a `mut T` (mutable reference). This means:
- You can assign to `@field` directly (e.g., `@count = @count + 1`)
- Returning `@field` returns a `mut T` reference, not an owned value
- To get an owned copy, use `@field.clone` for non-value types

```inko
impl Counter {
  fn pub mut increment -> mut Counter {
    @count = @count + 1
    self  # Returns mut Counter
  }

  fn pub count_copy -> Int {
    @count  # Int is a value type, copies automatically
  }

  fn pub name_copy -> String {
    @name.clone  # String is a value type, copies automatically
    # For non-value types like Array, .clone is required
  }
}
```

**Important:** To extract owned values from a `mut T` reference to a struct (e.g., from `config.gateway` which is `mut GatewaySettings`), read individual fields and reconstruct a new owned instance:

```inko
# config.gateway is mut GatewaySettings (mutable reference)
# Can't move it, but can read its fields
let gateway_owned = GatewaySettings(
  size_threshold: config.gateway.size_threshold,  # Int copies
  name: config.gateway.name.clone,                 # String copies
  items: config.gateway.items.clone,               # Array needs .clone
)
```

### Reference Type Decision Matrix

| Need | Use | Example |
|------|-----|---------|
| Read only, keep original | `ref T` | `fn size(data: ref Array[Int])` |
| Modify, keep original | `mut T` | `fn append(data: mut Array[Int])` |
| Take ownership, don't need original | `T` | `fn consume(data: Array[Int])` |
| Send to another process | `uni T` | `process.send(data)` |

**Rule of thumb:** Use `ref` by default, `mut` when modifying, owned `T` only when transferring ownership. Use `uni` when sending between processes.

### Borrow Counter Mechanics

Every heap-allocated value has a borrow counter:

```inko
let data = [1, 2, 3]  # borrow count = 0
let r1 = ref data     # borrow count = 1
let r2 = ref data     # borrow count = 2
# data dropped here → panic if count > 0
```

**Key insight:** Dropping happens when variable goes out of scope, not when you stop using it.

**Safe pattern:**

```inko
let data = [1, 2, 3]
{
  let r = ref data
  # use r here
}  # r dropped, borrow count decremented
# data safe to drop here
```

**Dangerous pattern:**

```inko
let data = [1, 2, 3]
let r = ref data
# ... lots of code ...
# data drops when function returns
# If r is still in scope, PANIC
```

### Value Types Behavior

**Copied on move:**

```inko
let a = "hello"      # String is a value type
let b = a            # a is copied
# Both a and b are usable
```

**Not value types (moved):**

```inko
let a = [1, 2, 3]    # Array is NOT a value type
let b = a            # a is moved
# Only b is usable
```

**Value type list:** `Int`, `Float`, `Bool`, `String`, `Nil`, processes

**Everything else moves** (Array, HashMap, custom types, etc.)

### Drop Timing

Values drop **deterministically** when ownership ends:

```inko
{
  let file = File.new("data.txt")
  # Use file
}  # file is dropped here automatically
```

**Benefits:**

- Reliable resource cleanup (files, sockets, locks)
- Predictable performance (no GC pauses)
- Consistent memory patterns

### The `recover` Expression

Create unique values by hiding outside variables:

```inko
let a = 10
let b = recover {
  [a]  # Only value types and unique types accessible inside
}
# b is uni Array[Int]
```

**Rules:**

- Only unique values, value types, or owned types containing sendable subtypes can cross `recover` boundaries
- Ensures data isolation for safe concurrency
