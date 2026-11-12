# Foreign Function Interface (FFI)

Inko supports calling C functions directly via FFI. This is essential for using external C libraries.

## Linking External Libraries

Use `import extern "library_name"` to link against C libraries:

```inko
# Link libsodium
import extern "sodium"

# Link libm (math library)
import extern "m"

# Link custom library
import extern "tantivy"
```

**Key points:**

- Library name should be without prefix (`lib`) or extension (`.so`, `.dylib`, `.dll`)
- Multiple `import extern` statements are allowed
- The linker will find the library in standard paths

## Declaring External Functions

Use `fn extern function_name(params) -> ReturnType` to declare C functions:

```inko
# Simple function with no parameters
fn extern sodium_init -> Int32

# Function with parameters
fn extern randombytes_buf(buf: Pointer[Uint8], len: Int64)

# Function returning pointer
fn extern sodium_version_string -> Pointer[Uint8]

# Function with multiple parameters
fn extern crypto_sign_keypair(pk: Pointer[Uint8], sk: Pointer[Uint8]) -> Int32
```

**Key points:**

- Use C integer types: `Int8`, `Int16`, `Int32`, `Int64`, `Uint8`, `Uint16`, `Uint32`, `Uint64`
- Use `Float32` or `Float64` for floating-point types
- Use `Pointer[T]` for pointer types (e.g., `Pointer[Uint8]` for `uint8_t*`)
- Omit return type for void functions

## Calling External Functions

Call extern functions just like regular Inko functions:

```inko
# No parameters
let result = sodium_init

# With parameters: cast Inko values to the C types used in the signature
let buf = ByteArray.filled(with: 0, times: 32)
randombytes_buf(buf.pointer, 32 as Int64)

# C types have no operators, so cast before comparing
if (result as Int) == 0 {
  # Success
}
```

## Type Conversions

Inko requires explicit type casting between C types and Inko types:

```inko
# Convert Inko Int to C Int64
let size = array.size
let c_size = size as Int64

# Convert C return value to Inko Int
let c_result = some_c_function()
let inko_result = c_result as Int

# Cast pointer types
let ptr = buffer.pointer as Pointer[Uint8]
```

Unlike Inko values, C types (`Int32`, `Uint64`, `Float64`, ...) don't define
methods or operators, so casts are required before doing anything with them.

## Pointer Types

Pointers are written `Pointer[T]`, where `T` is the pointed-to type:

```inko
# Pointer to bytes
let byte_ptr: Pointer[Uint8]

# Pointer to integers
let int_ptr: Pointer[Int64]

# Pointer to an extern struct
let time_ptr: Pointer[Timespec]
```

**There is no `Pointer[Pointer[T]]`.** Inko pointer-pointers are represented as
plain `Pointer[T]` values (a `char**` is just `Pointer[Uint8]`), and `Pointer`
itself is not a value you can call methods on.

**Creating, reading and writing pointers:**

```inko
# Create a pointer with `mut expr` (requires a mutable place)
let mut spec = Timespec(tv_sec: 0 as Int64, tv_nsec: 0 as Int64)
let ptr = mut spec

# Read/write fields through the pointer (no intermediate copy)
ptr.tv_sec = 400 as Int64

# Dereference: the 0 field returns a *copy* of the pointed-to value
let copy = ptr.0

# "NULL" is the integer zero cast to a pointer
let null_ptr = 0 as Pointer[Timespec]

# Check for NULL by casting back to Int
if (null_ptr as Int) == 0 {
  # Handle the NULL pointer
}

# Pointers to bytes: use String.pointer / ByteArray.pointer
let bytes = "abc".pointer
```

**Key points:**

- Inko has **no pointer arithmetic**: `ptr + 16` is invalid. Cast to `Int`,
  add, and cast back: `(ptr as Int + 16) as Pointer[Uint8]`
- Memory for FFI must be managed by you; use `std.alloc` (e.g.
  `alloc.allocate(size)`, `alloc.free(ptr)`) or the C library's own
  allocator/free function
- `std.ptr` exists but its methods are internal to the standard library

## Complete FFI Example

```inko
import extern "sodium"

# Declare extern functions
fn extern sodium_init -> Int32
fn extern randombytes_buf(buf: Pointer[Uint8], len: Int64)
fn extern crypto_hash_sha256(
  output: Pointer[Uint8],
  input: Pointer[Uint8],
  inlen: Int64
) -> Int32

# Inko wrapper type
type pub SodiumRandom {
  let @initialized: Bool
}

impl SodiumRandom {
  fn pub static new -> Result[SodiumRandom, String] {
    let result = sodium_init
    if (result as Int) == 0 or (result as Int) == 1 {
      Result.Ok(SodiumRandom(initialized: true))
    } else {
      Result.Error("Failed to initialize libsodium")
    }
  }

  fn pub random_bytes(size: Int) -> ByteArray {
    let buf = ByteArray.filled(with: 0, times: size)
    randombytes_buf(buf.pointer, size as Int64)
    buf
  }

  fn pub hash_sha256(input: ByteArray) -> Result[ByteArray, String] {
    let output = ByteArray.filled(with: 0, times: 32)
    let output_ptr = output.pointer
    let input_ptr = input.pointer
    let result = crypto_hash_sha256(
      output_ptr,
      input_ptr,
      input.size as Int64
    )
    if (result as Int) == 0 {
      Result.Ok(output)
    } else {
      Result.Error("Hash failed")
    }
  }
}
```

## FFI Safety Considerations

### Memory Safety

- Always check pointer validity before dereferencing
- Match allocation/deallocation pairs
- Be aware of ownership transfer across FFI boundary

### Type Safety

- Use explicit casts for pointer types
- Ensure integer sizes match between Inko and C
- Use correct signedness (Int vs Uint)

### Error Handling

- Check C function return values
- Handle null pointers
- Wrap FFI calls in safe Inko APIs

### Common Pitfalls

- Don't use `extern fn` syntax (deprecated)
- Don't try to use `std.ffi` module (doesn't exist in 0.21.1)
- Remember to link the library with `import extern`
- Use `Pointer[T]` not raw `Pointer`
- **0.20.0 breaking change:** `UInt8`/`UInt16`/`UInt32`/`UInt64` renamed to `Uint8`/`Uint16`/`Uint32`/`Uint64`

## Debugging FFI Issues

**"undefined reference to function_name":**

- Make sure you have `import extern "library_name"`
- Check that the library is installed on your system
- Verify that function name matches C library

**"expected a '=', found 'extern' instead":**

- Don't use old `extern fn` syntax
- Use `fn extern function_name` instead

**"the module 'std.ffi' couldn't be found":**

- Don't import std.ffi in Inko 0.21.1
- Use `import extern` and `fn extern` directly

**Type mismatch errors:**

- Use explicit casts: `value as Pointer[Uint8]`
- Convert between Inko and C types with `as`: `value as Int64`, `value as Int`
- Check pointer types match C function signatures
- **Important:** Int32 from FFI needs `as Int` cast before comparisons
- **Integer conversions:** `Int` isn't implicitly converted to `Int64` in signatures, so pass `value as Int64`
- **NULL pointers:** Use `(0 as Pointer[Uint64])` for NULL pointer parameters

**Ownership with FFI:**

- Field access returns `ref ByteArray`, use `.clone` to get an owned copy
- Passing `ref ByteArray` to a function expecting `ByteArray` is a compile error
- Use `.clone` when a value needs to be used after moving it to an FFI function

**FFI return value comparison:**

- Int32 from FFI needs explicit cast: `if (result as Int) == 0`
- Cannot directly compare Int32 with literal without casting

**Result type usage:**

- `.or_panic()` takes no arguments (uses Error value as message)
- For custom panic message: `.or_panic_with("message")`
- Pattern matching Result: must handle all cases (e.g., `Ok(true)` and `Ok(false)`)
