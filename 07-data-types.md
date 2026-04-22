# Data Types: Strings, Arrays, Option, Result

## String Operations

### String Concatenation

```inko
# Simple concatenation (O(n^2) for repeated operations)
let result = "Hello" + " " + "World"

# Use StringBuffer for O(n) performance
import std.string (StringBuffer)

let mut buffer = StringBuffer.new
buffer.push("Hello")
buffer.push(" ")
buffer.push("World")
let result = buffer.to_string
```

**Note:** `StringBuffer` was redesigned in 0.19.1 around `ByteArray` for improved memory efficiency.

### String Interpolation

```inko
let name = "World"
let greeting = "Hello, ${name}!"  # "Hello, World!"

let port = 3000
let msg = "Server on port ${port}"  # "Server on port 3000"
```

**Key points:**

- Use `${variable}` for interpolation
- Works with any type that has `.to_string`
- No format specifiers needed

### String Slicing (0.19.1 Update)

```inko
let text = "Hello, World!"

# substring() - character-based slicing, returns String (O(n))
let substring = text.substring(0, 5)  # "Hello" (start, end in characters)

# slice() - byte-based slicing, returns Slice[String] (non-copying view)
let view = text.slice(0, 5)  # Slice[String] (start, end in bytes)
let view_string = view.to_string  # Convert Slice to String if needed

# to_slice() - returns a Slice covering the entire string
let full_slice = text.to_slice  # Slice[String]
```

**Key points:**

- `.substring(start, end)` - character-based, returns `String`, O(n) complexity
- `.slice(start, end)` - byte-based, returns `Slice[String]`, non-copying view
- `.to_slice()` - returns `Slice[String]` covering entire string
- `Slice[T]` is a non-copying view - call `.to_string()` to get a `String`
- Slices work on `String`, `ByteArray`, and `Array`

### String to Bytes

```inko
let text = "Hello"
let bytes = text.to_bytes

### JSON Builder Pattern (NEW in 0.20.0)

Instead of manually constructing Maps for JSON output, use the builder pattern:

```inko
import std.json (Json)

# Old way (still works)
let map = Map.new
map.set('name', Json.String('Alice'))
map.set('age', Json.Int(42))
Json.Object(map).to_string

# New builder pattern
Json.object.string('name', 'Alice').int('age', 42).into_string

# Array builder
Json.array.string('hello').string('world').into_string
```

**Key points:**

- `Json.object` returns an `ObjectBuilder` — chain `.string(key, val)`, `.int(key, val)`, etc.
- `Json.array` returns an `ArrayBuilder` — chain typed value methods
- Both support `.into_string` to produce the final JSON string

# Access individual byte
match bytes.get(0) {
  case Ok(byte) -> {
    let byte_as_int = byte.to_int
  }
  case Error(_) -> # handle out of bounds
}
```

### String Methods

```inko
let text = "  hello  "

# Trim whitespace
let trimmed = text.trim  # "hello"

# Check if contains substring (returns Bool)
let has_hello = text.contains?("hello")  # true
let has_world = text.contains?("world")  # false

# Find index of substring (returns Option[Int])
match text.index_of("hello", 0) {
  case Some(pos) -> # Found at position pos
  case None -> # Not found
}

# Check if empty
let is_empty = text.size == 0

# Get size
let size = text.size

# Split
let parts = text.split(",")  # Returns Array[String]

# To uppercase/lowercase
let upper = text.to_upper
let lower = text.to_lower
```

### Single-Quoted vs Double-Quoted Strings

**Single-quoted strings** - escape sequences shown as-is:

```inko
let path = 'C:\Users\name'  # Backslashes are literal
let text = 'Hello\nWorld'   # Contains literal \n, not newline
```

**Double-quoted strings** - support escapes and interpolation:

```inko
let text = "Hello\nWorld"   # Contains actual newline
let name = "Alice"
let greeting = "Hello, ${name}!"  # Interpolation works

# Unicode escapes
let emoji = "Smile: \u{1F600}"
```

---

## Array Operations

### Array Creation

```inko
# Empty array
let empty = []

# Array with values
let numbers = [1, 2, 3, 4, 5]

# Array of specific size
let zeros = ByteArray.filled(with: 0, times: 10)
```

### Array Access (UPDATED in 0.19.1)

```inko
let arr = [1, 2, 3]

# NEW API: get() returns Result, not Option
match arr.get(0) {
  case Ok(value) -> # use value
  case Error(_) -> # index out of bounds
}

# Panic on out of bounds
let value = arr.get(0).or_panic("index out of bounds")

# Mutable access
let mut arr = [1, 2, 3]
match arr.get_mut(0) {
  case Ok(mut_ref) -> mut_ref = 10  # Modify through mutable reference
  case Error(_) -> {}
}
```

**CRITICAL CHANGE in 0.19.1:**

- `Array.get(index)` returns `Result[ref T, OutOfBounds]` — a **reference** to the element, not an owned copy. Use `.clone` on the extracted value for non-value types.
- `Array.get_mut(index)` returns `Result[mut T, OutOfBounds]` — a mutable reference
- `ByteArray.get(index)` also returns `Result`
- Do NOT use `.unwrap()` - it doesn't exist for Result types
- Use pattern matching or `.or_panic(message)` for quick conversions

**Migration from old API:**

| Before (0.18.x) | After (0.19.1) |
| --- | --- |
| `arr.get(0)` | `arr.get(0).or_panic` |
| `arr.get_mut(0)` | `arr.get_mut(0).or_panic` |
| `arr.opt(0)` | `arr.get(0)` |
| `arr.opt_mut(0)` | `arr.get_mut(0)` |
| `arr.remove_at(0)` | `arr.remove_at(0).or_panic` |
| `arr.remove(key)` | `arr.remove(key).or_panic` |
| `Result.ok` to convert | `result.ok` for Option[T] from Result[T, E] |

### Array Slicing (NEW in 0.19.1)

```inko
let arr = [1, 2, 3, 4, 5]

# New slice API - non-copying view (returns Slice[T])
let view = arr.slice(0, 3)  # Slice[Int] containing [1, 2, 3]
let view_array = view.to_array  # Convert Slice to Array if needed
```

### Array Methods

```inko
let mut arr = [1, 2, 3, 4, 5]

# Size
let size = arr.size

# Is empty
let is_empty = arr.size == 0

# Push
arr.push(6)

# Pop
match arr.pop {
  case Some(value) -> # use value
  case None -> # array was empty
}

# Iteration
for item in arr {
  # Process item
}
```

---

## Option and Result Types

### Option

```inko
# Create Option
let some_value = Option.Some(42)
let no_value = Option.None

# Pattern match
match some_value {
  case Some(v) -> # use v
  case None -> # handle none
}

# Helper methods
let is_some = some_value.some?
let is_none = some_value.none?
```

### Result

```inko
# Create Result
let ok_result = Result.Ok(42)
let error_result = Result.Error("Something went wrong")

# Pattern match
match result {
  case Ok(value) -> # use value
  case Error(e) -> # handle error
}

# Helper methods
let is_ok = result.ok?
let is_error = result.error?
```

### Converting Between Types

```inko
# Result to Option
match result.ok {
  case Some(v) -> v
  case None -> default
}

# Option to Result
match optional {
  case Some(v) -> Result.Ok(v)
  case None -> Result.Error("No value")
}
```

---

## ByteArray Operations

```inko
import std.bytes (ByteArray)

# Convert string to byte array
let bytes = 'Test'.to_byte_array

# Create empty byte array
let result = ByteArray.new

# Byte arrays are mutable and growable
result.push(42)

# Slicing ByteArray
let bytes = "hello".to_byte_array
let slice = bytes.slice(0, 3)  # Slice[ByteArray]
```

**Key points:**

- Use `.to_byte_array` to convert strings
- `ByteArray.new` creates empty mutable byte array
- Common for binary data handling
- `.slice()` returns `Slice[ByteArray]` (non-copying view)

## The Bytes and ToSlice Traits (0.19.1)

For generic code that works with different slice-like values:

```inko
import std.bytes (Bytes, ToSlice)

# Generic function that accepts String, ByteArray, or their Slices
fn example[B: Bytes, S: ToSlice[B]](value: ref S) -> String {
  value.to_slice.slice(0, 5).to_string
}

type async Main {
  fn async main {
    # Works with String
    example('hello')               # => 'hello'

    # Works with ByteArray
    example('hello'.to_byte_array) # => 'hello'

    # Works with Slice
    example('hello'.to_slice)      # => 'hello'
  }
}
```

**Key points:**

- `Bytes` trait is implemented by `String`, `ByteArray`, `Slice[String]`, `Slice[ByteArray]`
- `ToSlice` trait provides `.to_slice()` method
- Use for generic code that handles multiple slice-like types
- `Write[E]` trait now uses `Bytes` instead of separate methods
