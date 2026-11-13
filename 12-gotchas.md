# Common Gotchas

> **FOR LLMs:** These are the most frequent mistakes when generating Inko code. Each mistake will cause a **compile-time error**. Review this section carefully before generating code.

## Summary Table of Common Mistakes

| # | Mistake | From Language | Severity |
|---|---------|---------------|----------|
| 1 | `=>` instead of `->` in match | Rust/Scala | COMPILE ERROR |
| 2 | `class` instead of `type` | Python/Java | COMPILE ERROR |
| 3 | Explicit `self` parameter | Rust/Python | COMPILE ERROR |
| 4 | `not x` for boolean negation | Python/Lua | COMPILE ERROR |
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
| 17 | Public non-async instance methods on `async` types | Rust/Other | COMPILE ERROR |
| 18 | Passing directories to `inko fmt --check` | N/A | COMMAND ERROR |
| 19 | Assuming `String.starts_with` is in the stdlib | Rust/Other | COMPILE ERROR |

______________________________________________________________________

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

## 4. Boolean negation is `!`, not `not`

**Wrong:**

```inko
if not value.empty? { }
let x = not done
```

**Right:**

```inko
if !value.empty? { }
let x = !done
```

The `not` keyword doesn't exist; `!` is the only boolean negation operator.

**Note:** `+=`, `-=`, `*=`, `/=`, and `%=` *do* exist, e.g. `@counter += 1` is
valid for integers (and any type with the matching operator).

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
let value = array.get(0).or_panic
let value = array.get(0).or_panic_with("index out of bounds")
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

______________________________________________________________________

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

**File I/O imports:** there is no `File` type. Open files with
`ReadOnlyFile`, `WriteOnlyFile`, or `ReadWriteFile` from `std.fs.file`:

```inko
import std.bytes (ByteArray)
import std.fs.file (ReadOnlyFile)

let file = ReadOnlyFile.new('data.txt'.to_path).or_panic
let bytes = ByteArray.new
file.read_all(bytes).or_panic
```

`import std.fs.file (File)` fails because no such type exists, and
`std.fs.path` only provides path manipulation (`Path`).

### Use Map.set, Not Map.insert

`Map` has no `insert()` method. Use `Map.set`, which returns the previous value
(if any) as an `Option[V]`:

```inko
import std.map (Map)

let map: Map[String, String] = Map.new

map.set("subject", "Test")
map.set("from", "user@example.com")

match map.get("subject") {
  case Ok(value) -> value  # => 'Test'
  case Error(_) -> "missing"
}
```

`Map.try_set` returns `Result[mut V, (K, mut V, V)]` when you need to insert
only if the key is absent.

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
- Use relative paths like `../local-package` for local development
- The local repository must have a tag `vVERSION`; `inko pkg sync` clones that
  tag before checking out the checksum commit
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

## 11. Parameter mutability: `param: mut Type` only

Parameters are immutable by default: you can't assign them a new value. The only
way to get a mutable parameter is a mutable **reference**, written with `mut`
on the *type*:

- **`param: mut Type`** — the parameter is a mutable reference to a value of
  type `Type`. The caller passes `mut value`, and the method can modify the
  value through the reference.
- **`mut param: Type`** — invalid syntax. There is no "rebindable parameter"
  form; introduce a mutable local instead.

**Wrong (`mut` before the parameter name is a syntax error):**

```inko
fn process(mut input: String) -> String {  # Error: expected an identifier
  input = input.trim
  input
}
```

**Right (mutable reference for in-place mutation):**

```inko
fn grow(values: mut Array[Int]) {
  values.push(1)
}

let mut items = [1, 2]
grow(mut items)
```

**Right (rebindable local for reassignment):**

```inko
fn process(input: String) -> String {
  let mut out = input.trim
  out = out.to_upper
  out
}
```

Mutable borrows are only valid for heap types: `fn f(value: mut Int)` is an
error because `Int` has no mutable state.

**Rule of thumb:** If you need to modify the value the caller owns, use
`param: mut Type`. If you only need to reassign a local inside the function,
declare a new `let mut` variable.

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

fn read_file(path: String) -> Result[String, Error] {
  # ...
}
```

This applies to any type annotation: function return types, parameter types, field types, and let bindings. Import the type from its module and use the short name.

## 14. `Array.get` returns `ref T`, not owned `T`

`Array.get(index)` returns `Result[ref T, OutOfBounds]` — a **reference** to the element, not an owned copy. To get an owned copy, call `.clone` on the extracted value. This matters for types that are not value types (String, Int, Float, Bool are value types and copy automatically).

**Wrong (for non-value types):**

```inko
match array.get(0) {
  case Ok(item) -> {
    # Error: expected an owned Array[Int], found a ref Array[Int]
    some_function(item)
  }
  case Error(_) -> {}
}
```

Assigning `item` to another variable copies the *reference* (it doesn't move the
value), so the error only shows up where an owned value is required.

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

`read_line` reads into a `ByteArray` (`BufferedReader.read_line(into: mut ByteArray, inclusive: Bool)`).

**Wrong (infinite loop on EOF):**

```inko
loop {
  match inp.read_line(into: mut buf, inclusive: false) {
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
  match inp.read_line(into: mut buf, inclusive: false) {
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

## 17. Synchronous instance methods on `async` types must be private

An `async` type may expose public **async** instance methods and public static
methods. A synchronous instance method with `pub` is rejected:

```inko
type async Dispatcher {
  # OK: async instance methods may be public
  fn pub async run { }

  # ERROR: non-async instance methods on async types must be private
  fn pub mut load { }

  # OK
  fn mut load { }
}
```

Static constructors also cannot call private instance methods. The compiler
reports `the method 'load' exists but is private`:

```inko
# ERROR
fn pub static with_path(path: String) -> Dispatcher {
  let dispatcher = Dispatcher()

  dispatcher.load(path)
  dispatcher
}
```

Put reusable setup logic in a module-level function, or expose a public method
on a non-async type that the constructor calls:

```inko
# OK: module-level helper, callable from the static constructor
fn load(path: String) -> Array[Record] { ... }

type async Dispatcher {
  fn pub static with_path(path: String) -> Dispatcher {
    Dispatcher(records: load(path))
  }
}
```

## 18. `inko fmt --check` does not accept directories

Inko 0.21.1 treats its arguments as files. Passing `src/` fails with
`failed to read src/: Is a directory`:

```bash
# Error
inko fmt --check src/ test/

# Right
inko fmt --check $(find src test -name '*.inko')
```

`inko fmt` (without `--check`) has the same limitation; pass the files found by
`find` when formatting a tree.

## 19. `String.starts_with` is not in the standard library

Plain Inko 0.21.1 does not provide `String.starts_with`, `String.ends_with`,
`String.contains`, or `String.is_empty`. Projects sometimes add these in a
local `std/string_ext.inko` module, so code that compiles in one project can
fail in another or inside a shared package:

```inko
# ERROR in plain Inko: method 'starts_with' isn't defined for type 'String'
if name.starts_with('/') { ... }
```

Compare explicitly, or import the project's extension module when one exists:

```inko
if name.size > 0 and name.substring(0, 1) == '/' { ... }
```

Shared packages should avoid project-local string extensions entirely.
