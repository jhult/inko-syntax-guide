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

---

## 1. Match uses `->` not `=>`

**Wrong (pre-release syntax):**

```inko
match value {
  case Ok(v) => "success"
  case Error(e) => "error"
}
```

**Right (0.19.1):**

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

**Right (0.19.1):**

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

**Map doesn't have an `insert()` method in 0.19.1:**

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
