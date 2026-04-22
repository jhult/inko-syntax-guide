# Common Gotchas

> **FOR LLMs:** These are the most frequent mistakes when generating Inko code. Each mistake will cause a **compile-time error**. Review this section carefully before generating code.

## Summary Table of Common Mistakes

| # | Mistake | From Language | Severity |
|---|---------|---------------|----------|
| 1 | `=>` instead of `->` in match | Rust/Scala | COMPILE ERROR |
| 2 | `class` instead of `type` | Python/Java | COMPILE ERROR |
| 3 | Explicit `self` parameter | Rust/Python | COMPILE ERROR |
| 4 | `+=`, `-=` operators | Most languages | COMPILE ERROR |
| 5 | `Some`/`None` for array access | Rust (pre-0.19) | COMPILE ERROR |
| 6 | Single IP to TcpClient | N/A | COMPILE ERROR |
| 7 | Missing parentheses in comparisons | N/A | COMPILE ERROR |
| 8 | Confusing `.slice()` and `.substring()` | N/A | LOGIC ERROR |
| 9 | Overflow behavior differences | N/A | RUNTIME PANIC |
| 10 | `case Option.None` in match patterns | Rust | COMPILE ERROR |
| 11 | `mut param: Type` for mutable references | Rust | COMPILE ERROR |
| 12 | `(-x)` unary negation | Most languages | COMPILE ERROR |
| 13 | Nested module paths in type annotations | Rust/Python | COMPILE ERROR |
| 14 | `Array.get` returns `ref T`, not owned | Rust | COMPILE ERROR |
| 15 | `read_line` EOF returns `Ok(0)`, not `Error` | Most languages | LOGIC ERROR |
| 16 | `UInt8`/`UInt32` instead of `Uint8`/`Uint32` | Pre-0.20 | COMPILE ERROR |

---

## 1. Match uses `->` not `=>`

**Wrong (pre-release syntax):**

```inko
match value {
  case Ok(v) => "success"
  case Error(e) => "error"
}
```

**Right (0.20.0):**

```inko
match value {
  case Ok(v) -> "success"
  case Error(e) -> "error"
}
```

## 2. No `class` keyword

**Wrong:**

```inko
class MyClass { }
```

**Right:**

```inko
type MyClass { }
```

## 3. No explicit `self` parameter

**Wrong:**

```inko
fn pub mut do_something(self, value: Int) -> Int { }
fn pub get_value(self: Person) -> String { }
```

**Right:**

```inko
fn pub mut do_something(value: Int) -> Int { }
fn pub get_value -> String { }
```

## 4. No compound assignment operators

**Wrong:**

```inko
@counter += 1
@total -= amount
```

**Right:**

```inko
@counter = @counter + 1
@total = @total - amount
```

## 5. Array.get() returns Result, not Option

**Wrong:**

```inko
let value = array.get(0).unwrap  # unwrap doesn't exist
match array.get(0) {
  case Some(v) -> v  # get() doesn't return Option anymore!
  case None -> default
}
```

**Right (0.20.0):**

```inko
match array.get(0) {
  case Ok(v) -> v
  case Error(_) -> default
}

# Or for quick conversion:
let value = array.get(0).or_panic("index out of bounds")
```

## 6. TcpClient expects Array[IpAddress]

**Wrong:**

```inko
TcpClient.new(addr, 3000)
```

**Right:**

```inko
let addrs = [addr]
TcpClient.new(addrs, 3000)
```

## 7. Operator precedence - use parentheses

**Wrong:**

```inko
if size > 256 * 1024 * 1024 {  # Error: comparison with Bool
if page_num < page_count - 1 {    # Error: method '-' not defined for Bool
```

**Right:**

```inko
if size > (256 * 1024 * 1024) {
if page_num < (page_count - 1) {
```

## 8. String slicing - understand the differences

**`.substring()` returns a String** (character-based, O(n)):

```inko
let sub = text.substring(0, 5)  # Returns String
```

**`.slice()` returns a Slice[T]** (byte-based, non-copying view):

```inko
let view = text.slice(0, 5)  # Returns Slice[String]
let as_string = view.to_string  # Convert to String if needed
```

**Key difference:**

- `.substring(start, end)` - character positions, allocates new String
- `.slice(start, end)` - byte positions, returns non-copying Slice
- For `String`/`ByteArray`, slices are byte-based (be careful with multi-byte UTF-8)

## 9. Integer overflow handling

**NEW in 0.19.1:**

- Debug builds: panic on overflow
- Release builds: wrap using two's complement
- Use checked/wrapping arithmetic methods if you need specific behavior

---

## Additional Gotchas

### Subtraction Operator Precedence Issue

**Wrong:**

```inko
while i <= haystack_bytes.size - needle_bytes.size {
  # Error: Parses as (i <= haystack_bytes.size) - needle_bytes.size
  # Because `<=` has lower precedence than `-`
}
```

**Right:** Calculate the bound separately:

```inko
let max_i = haystack_bytes.size - needle_bytes.size
while i <= max_i {
  # ...
}
```

### String Slice Syntax Error

**Inko doesn't support Python-style slice ranges:**

**Wrong:**

```inko
let end = match find_substring(d[start..], "\"") {  # Error!
```

**Right:** Implement a separate function:

```inko
fn find_substring_from(text: String, pattern: String, from: Int) -> Result[Int, String] {
  # ... implementation
}

let end = match find_substring_from(d, "\"", start) {
    case Ok(pos) -> pos
    case Error(_) -> return Option.None
  }
```

### Import Statement Issues

**File I/O imports:**

```inko
# Correct import for File operations
import std.fs.file (File)
```

### Working Around Map.insert() Limitation

**Map doesn't have an `insert()` method in 0.20.0:**

**Workaround 1:** Use `Array[(String, String)]` instead:

```inko
let mut headers = []
headers.push(("subject", "Test"))
headers.push(("from", "user@example.com"))

# Lookup
fn get_value(headers: Array[(String, String)], key: String) -> Option[String] {
  for entry in headers.iter {
    match entry {
      case (k, v) -> {
        if k == key {
          return Option.Some(v)
        }
      }
    }
  }
  Option.None
}
```

**Workaround 2:** Use iterative search for small datasets.

### Local Package Dependencies

**Configuring local path dependencies in inko.pkg:**

```
# inko.pkg uses the require command syntax
# require URL VERSION CHECKSUM

# Local path with commit SHA:
require ../local-dependency 0.1.0 abc123def456789...

# After publishing to GitHub:
require github.com/user/local-dependency 0.1.0 abc123def456789...
```

**Key points:**

- Use `require URL VERSION CHECKSUM` format
- Get commit SHA with `git log -1 --format='%H'`
- Use relative paths like `../local-dependency` for local development
- After publishing to GitHub, switch to Git URLs

## 10. Match patterns use `None`/`Some`, expressions use `Option.None`/`Option.Some`

In match **patterns**, use unqualified names (`case None`, `case Some(v)`). In **expressions** (assignments, return values, match bodies), use fully qualified names (`Option.None`, `Option.Some(v)`).

**Wrong:**

```inko
match result {
  case Option.Some(v) -> v    # Error: Option.Some is not a valid pattern
  case Option.None -> default  # Error: Option.None is not a valid pattern
}

let x = Some(42)     # Error: Some is not a valid expression
let y = None         # Error: None is not a valid expression
```

**Right:**

```inko
match result {
  case Some(v) -> v
  case None -> default
}

let x = Option.Some(42)
let y = Option.None
```

This also applies to `Result`: use `case Ok(v)` / `case Error(e)` in patterns, but `Result.Ok(v)` / `Result.Error(e)` in expressions.

## 11. Parameter mutability: `param: mut Type` vs `mut param: Type`

These two syntaxes mean completely different things.

- **`param: mut Type`** — the parameter is a mutable **reference** to a value of type `Type`. The caller passes `mut value` and the function can modify the value through the reference.
- **`mut param: Type`** — the parameter is an owned value that the local variable can be **reassigned** to (like `let mut`). The caller passes an owned value and the function can rebind the variable.

**Wrong (trying to pass a mutable reference):**

```inko
fn increment(value: mut Int) {
  value = value + 1
}
let mut count = 0
increment(mut count)      # This works, but...
increment(mut count: Int)  # Error: wrong syntax
```

**Wrong (trying to make a rebindable local):**

```inko
fn process(mut data: Array[Int]) {
  data.push(1)  # Error: can't mutate through a rebinding, only through mut reference
}
```

**Right (mutable reference for mutation):**

```inko
fn pub mut handle(request: mut Request) -> Response {
  # request is a mutable reference, can modify through it
}
```

**Right (rebindable local for reassignment):**

```inko
fn process(mut input: String) -> String {
  input = input.trim  # rebinding the local variable
  input
}
```

**Rule of thumb:** If you need to modify the value the caller owns, use `param: mut Type`. If you just need to reassign the local variable within the function, use `mut param: Type`.

## 12. Unary negation `(-x)` is not valid syntax

Inko does not support parenthesized unary negation like `(-x)`. Use `0 - x` instead.

**Wrong:**

```inko
let neg = (-value)     # Error
let days = (-ttl)      # Error
```

**Right:**

```inko
let neg = 0 - value
let days = 0 - ttl
```

Note: simple `-value` (without parentheses) works for literal negation, but the parenthesized form `(-x)` does not.

## 13. Nested module paths don't work in type annotations

You cannot use nested paths like `std.io.Error` directly in type annotations. Import the type and use its short name.

**Wrong:**

```inko
fn read_file -> Result[String, std.io.Error] {  # Error: nested path in type
```

**Right:**

```inko
import std.io (Error)

fn read_file -> Result[String, Error] {
```

This applies to any type annotation: function return types, parameter types, field types, and let bindings. Import the type from its module and use the short name.

## 14. `Array.get` returns `ref T`, not owned `T`

`Array.get(index)` returns `Result[ref T, OutOfBounds]` — a **reference** to the element, not an owned copy. To get an owned copy, call `.clone` on the extracted value. This matters for types that are not value types (String, Int, Float, Bool are value types and copy automatically).

**Wrong (for non-value types):**

```inko
match array.get(0) {
  case Ok(item) -> {
    let owned = item  # Error: item is ref T, can't move from a reference
    some_function(item)  # Error: can't pass ref where owned is expected
  }
  case Error(_) -> {}
}
```

**Right:**

```inko
match array.get(0) {
  case Ok(item) -> {
    let owned = item.clone  # Get an owned copy
    some_function(item.clone)  # Clone if function takes owned value
  }
  case Error(_) -> {}
}
```

**Same applies to `Array.get_mut`:** it returns `Result[mut T, OutOfBounds]` — a mutable reference. Use `.clone` if you need an owned copy.

**Value types are the exception:** `Int`, `Float`, `Bool`, `String`, `Nil` are copied automatically and don't need `.clone`.

## 15. `BufferedReader.read_line` returns `Ok(0)` at EOF

When reading from stdin or a file, `read_line` signals EOF by returning `Ok(0)` (zero bytes read), **not** an `Error`. You must check the byte count to detect EOF.

**Wrong (infinite loop on EOF):**

```inko
loop {
  match inp.read_line(into: buf, inclusive: false) {
    case Ok(_) -> {
      # Process line — but this runs even on EOF!
      # The loop never terminates.
    }
    case Error(_) -> break  # Only breaks on I/O error, not EOF
  }
}
```

**Right:**

```inko
loop {
  match inp.read_line(into: buf, inclusive: false) {
    case Ok(n) -> {
      if n == 0 { break }  # EOF: zero bytes read
      # Process line...
    }
    case Error(_) -> break
  }
}
```

The `n` value is the number of bytes read. `0` means EOF (no more data). Any positive value means data was read.

## 16. FFI unsigned integer types renamed: `UIntN` → `UintN`

Inko 0.20.0 renamed the FFI C unsigned integer types from `UIntN` to `UintN` (lowercase `i`).

**Wrong (pre-0.20.0):**

```inko
fn extern randombytes_buf(buf: Pointer[UInt8], len: Int64)
```

**Right (0.20.0):**

```inko
fn extern randombytes_buf(buf: Pointer[Uint8], len: Int64)
```

This affects all unsigned FFI integer types: `Uint8`, `Uint16`, `Uint32`, `Uint64`.
