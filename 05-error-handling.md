# Error Handling

Inko's error handling is inspired by "The Error Model" and provides compile-time guarantees that every error is handled.

## Error Types

Inko distinguishes between two error categories:

1. **Recoverable errors** - Handled at runtime using `try`
2. **Critical errors (panics)** - Abort the program for unrecoverable situations

## Method Signatures with Errors

Methods that may fail use the `!! TypeName` annotation:

```inko
fn pub static open(path: String) !! Error -> File {
  # Implementation
}
```

**Key points:**

- Methods specify exactly ONE throwable error type
- Errors are lightweight values (not exceptions)
- No automatic stack unwinding
- Throw operations equal return statements in cost

## The `try` Keyword

Basic form - re-throws the error:

```inko
fn pub read_file -> Result[String, Error] {
  let file = try File.open("data.txt")  # If error, return it
  # Use file
}
```

## The `try!` Keyword (Panic)

Panics on error - only use for unrecoverable errors:

```inko
let file = try! File.open("config.txt")
# If this fails, program aborts with error message
```

**Use panics only when:**

- Errors result from incorrect code (logic bugs)
- No runtime recovery is possible
- Program requires missing critical resources

## The `try...else` Pattern

Explicit error handling:

```inko
let file = try File.open("data.txt") else {
  return default_value
}

# Or capture the error
let file = try File.open("data.txt") else (error) {
  stderr.print("Failed to open file: ${error}")
  return Result.Error(error)
}
```

**Common patterns:**

```inko
# Early return
let value = try operation else return

# Return error
let value = try operation else (e) return Result.Error(e)

# Provide default
let value = try operation else (e) {
  log_error(e)
  default_value
}

# Custom error message
let value = try operation else (e) {
  panic("Critical failure: ${e}")
}
```

## Compile-Time Guarantees

Inko's compiler ensures:

- Every error path is handled in some way (try, try!, try...else)
- Methods correctly declare throwable error types
- Error types match at call sites

This prevents the silent error swallowing common in exception-based systems.

## Error Handling vs Exceptions

**Unlike exceptions:**

- No automatic stack unwinding
- No hidden control flow
- No stack traces (errors are plain values)
- Explicit handling required at each call site
- Single error type per method (not multiple exception types)

**Performance:**

- `throw` = return statement
- `try` = flag check + conditional branch
- No heap allocations for stack unwinding
- Very low overhead

## Best Practices

**DO:**

- Use `Result[T, E]` for errors that callers should handle
- Use `try...else` for explicit error handling
- Keep error types simple and focused
- Include context in error messages

**DON'T:**

- Don't use `try!` for recoverable errors
- Don't panic for I/O errors or user input
- Don't create deeply nested try...else chains (factor into functions)

---

## Result Type Patterns

### Result Type

```inko
fn pub divide(a: Int, b: Int) -> Result[Int, String] {
  if b == 0 {
    Result.Error("Division by zero")
  } else {
    Result.Ok(a / b)
  }
}

# Usage
match divide(10, 2) {
  case Ok(result) -> # use result
  case Error(e) -> # handle error
}
```

### Bare Ok/Error in Return Statements

**Important**: When the return type is `Result`, you can use bare `Ok(...)` and `Error(...)` in return statements:

```inko
fn pub foo() -> Result[String, String] {
  if condition {
    return Ok("success")  # Bare Ok works in return
  }
  return Error("failed")  # Bare Error works in return
}
```

But in match expressions or other contexts, you must use `Result.Ok(...)`:

```inko
match some_condition {
  case true -> Result.Ok("value")   # Must use Result.Ok
  case false -> Result.Error("error")  # Must use Result.Error
}
```

### Error Propagation

```inko
fn pub multi_step() -> Result[String, String] {
  match step_one {
    case Ok(result) -> {
      match step_two(result) {
        case Ok(final) -> Result.Ok(final)
        case Error(e) -> Result.Error(e)
      }
    }
    case Error(e) -> Result.Error(e)
  }
}
```

**Note:** Inko doesn't have try-catch or the `?` operator. Use Result types and pattern matching.
