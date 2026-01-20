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
fn extern randombytes_buf(buf: Pointer[UInt8], len: Int64)

# Function returning pointer
fn extern sodium_version_string -> Pointer[UInt8]

# Function with multiple parameters
fn extern crypto_sign_keypair(pk: Pointer[UInt8], sk: Pointer[UInt8]) -> Int32
```

**Key points:**

- Use C integer types: `Int8`, `Int16`, `Int32`, `Int64`, `UInt8`, `UInt16`, `UInt32`, `UInt64`
- Use `Float32` or `Float64` for floating-point types
- Use `Pointer[T]` for pointer types (e.g., `Pointer[UInt8]` for `uint8_t*`)
- Omit return type for void functions

## Calling External Functions

Call extern functions just like regular Inko functions:

```inko
# No parameters
let result = sodium_init

# With parameters
let buf = ByteArray.filled(with: 0, times: 32)
randombytes_buf(buf.to_pointer as Pointer[UInt8], 32)

# Check return value
if result == 0 {
  # Success
}
```

## Type Conversions

Inko requires explicit type casting between C types and Inko types:

```inko
# Convert Inko Int to C Int64
let size = array.size
let c_size = size.to_int64

# Convert C return value to Inko Int
let c_result = some_c_function()
let inko_result = c_result.to_int

# Cast pointer types
let ptr = buffer.to_pointer as Pointer[UInt8]
```

## Pointer Types

Use typed pointers for safety:

```inko
# Pointer to bytes
let byte_ptr: Pointer[UInt8]

# Pointer to pointer (e.g., char** in C)
let ptr_ptr: Pointer[Pointer[UInt8]]

# Pointer to integers
let int_ptr: Pointer[Int64]
```

**Working with pointers:**

```inko
# Allocate memory
let ptr = Pointer.alloc(size)

# Write to pointer
ptr.write_u8(value)

# Read from pointer
let value = ptr.read_u8

# Offset pointer
let next_ptr = ptr.offset(1)

# Check if null
if ptr.is_null {
  # Handle null pointer
}

# Free memory
Pointer.dealloc(ptr, size)
```

## Complete FFI Example

```inko
import extern "sodium"

# Declare extern functions
fn extern sodium_init -> Int32
fn extern randombytes_buf(buf: Pointer[UInt8], len: Int64)
fn extern crypto_hash_sha256(
  output: Pointer[UInt8],
  input: Pointer[UInt8],
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
    let ptr = buf.to_pointer as Pointer[UInt8]
    randombytes_buf(ptr, size as Int64)
    buf
  }

  fn pub hash_sha256(input: ByteArray) -> Result[ByteArray, String] {
    let output = ByteArray.filled(with: 0, times: 32)
    let output_ptr = output.to_pointer as Pointer[UInt8]
    let input_ptr = input.to_pointer as Pointer[UInt8]
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
- Use correct signedness (Int vs UInt)

### Error Handling

- Check C function return values
- Handle null pointers
- Wrap FFI calls in safe Inko APIs

### Common Pitfalls

- Don't use `extern fn` syntax (deprecated)
- Don't try to use `std.ffi` module (doesn't exist in 0.19.1)
- Remember to link the library with `import extern`
- Use `Pointer[T]` not raw `Pointer`

## Debugging FFI Issues

**"undefined reference to function_name":**

- Make sure you have `import extern "library_name"`
- Check that the library is installed on your system
- Verify that function name matches C library

**"expected a '=', found 'extern' instead":**

- Don't use old `extern fn` syntax
- Use `fn extern function_name` instead

**"the module 'std.ffi' couldn't be found":**

- Don't import std.ffi in Inko 0.19.1
- Use `import extern` and `fn extern` directly

**Type mismatch errors:**

- Use explicit casts: `value as Pointer[UInt8]`
- Convert between Inko and C types: `.to_int64`, `.to_int`
- Check pointer types match C function signatures
- **Important:** Int32 from FFI needs `as Int` cast before comparisons
- **Integer conversions:** Pass Int values as Int64 to FFI functions with Int64 parameters using `value as Int64`
- **NULL pointers:** Use `(0 as Pointer[UInt64])` for NULL pointer parameters

**Ownership with FFI:**

- Field access returns `ref ByteArray`, use `.clone` to get owned copy
- Passing `ref ByteArray` to function expecting `ByteArray` causes compile error
- Use `.clone()` when value needs to be used after moving to FFI function

**FFI return value comparison:**

- Int32 from FFI needs explicit cast: `if (result as Int) == 0`
- Cannot directly compare Int32 with literal without casting

**Result type usage:**

- `.or_panic()` takes no arguments (uses Error value as message)
- For custom panic message: `.or_panic_with("message")`
- Pattern matching Result: must handle all cases (e.g., `Ok(true)` and `Ok(false)`)
