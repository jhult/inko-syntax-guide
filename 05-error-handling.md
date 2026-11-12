# Error Handling

Inko's error handling is inspired by "The Error Model" and provides compile-time guarantees that every error is handled.

## Error Types

Inko distinguishes between two error categories:

1. **Recoverable errors** - Handled at runtime using `try`, `throw`, `Result` and `Option`
2. **Critical errors (panics)** - Abort the program for unrecoverable situations

## Fallible Methods Return `Result` (or `Option`)

There is no dedicated error syntax in a signature. A method that can fail simply
returns a `Result[T, E]` (or an `Option[T]`) and uses `throw` to produce the
error value:

```inko
type pub File {
  let @path: String
}

type pub OpenError {
  let @message: String

  fn pub static new(message: String) -> OpenError {
    OpenError(message: message)
  }
}

impl File {
  fn pub static open(path: String) -> Result[File, OpenError] {
    if path.size == 0 {
      throw OpenError.new('the path is empty')
    }

    Result.Ok(File(path: path))
  }
}
```

**Key points:**

- The error type is the `E` in `Result[T, E]`: exactly one error type per method
- `throw` is only allowed in methods and closures that return `Option` or `Result`
- Errors are lightweight values (usually an `enum`), not exceptions
- No automatic stack unwinding
- Throw operations equal return statements in cost

## The `try` Keyword

`try` propagates an error to the caller: if the value is `Error(_)` (or `None`),
the enclosing method returns that error; otherwise you get the inner value.

```inko
fn read_file(path: String) -> Result[String, OpenError] {
  let file = try File.open(path)  # On Error, returns it from this method
  Result.Ok(file.path)
}
```

**Key points:**

- `try` can only be used in a method or closure that returns `Option` or `Result`
- `try` does not panic and has no `!` form
- `try` handles the error by returning it to the caller; use `match` when you
  want to handle the error locally

## Handling Errors Locally

To react to an error instead of propagating it, match on the `Result`:

```inko
fn read_or_default(path: String) -> String {
  match File.open(path) {
    case Ok(file) -> file.path
    case Error(e) -> "could not open the file: ${e.message}"
  }
}
```

## Panicking

`panic` aborts the process. Use it only for unrecoverable situations:

```inko
let config = File.open("config.txt").or_panic   # Uses the error as the message
let data = File.open("config.txt").or_panic_with("missing config file")
panic("unreachable")                            # Explicit panic
```

`try` does not have a panicking variant, but note that `try expr else ...` is
**not** error handling: the `else` belongs to the surrounding `let` pattern
(see [04-pattern-matching.md](04-pattern-matching.md)), so it never runs.

**Use panics only when:**

- Errors result from incorrect code (logic bugs)
- No runtime recovery is possible
- Program requires missing critical resources

## Compile-Time Guarantees

Inko's compiler ensures:

- `throw` and `try` are only used where an `Option`/`Result` is returned
- The thrown error type is compatible with the declared `Result` error type
- Every `try` is tied to a method that declares a matching error type, so you
  can't accidentally propagate an error that the signature doesn't mention
- A `Result` that is produced but not used triggers an `unused-result` warning;
  discard it explicitly with `let _ = ...` if that's intended

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
- Use `throw` + `try` to keep the happy path readable
- Keep error types simple and focused (one `enum` per module is idiomatic)
- Include context in error messages

**DON'T:**

- Don't use `panic`/`or_panic` for recoverable errors
- Don't panic for I/O errors or user input
- Don't create deeply nested `match` chains (factor into functions)

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

### Always Qualify `Result.Ok`/`Result.Error` in Expressions

`Ok(...)` and `Error(...)` are only valid as **patterns**. Anywhere else —
including `return` statements — use `Result.Ok(...)` and `Result.Error(...)`:

```inko
fn pub foo(condition: Bool) -> Result[String, String] {
  if condition {
    return Result.Ok("success")  # Bare Ok is NOT valid here
  }

  return Result.Error("failed")  # Bare Error is NOT valid here
}
```

```inko
match some_condition {
  case true -> Result.Ok("value")      # Must use Result.Ok
  case false -> Result.Error("error")  # Must use Result.Error
}
```

The same rule applies to `Option`: `case Some(v)` / `case None` in patterns,
`Option.Some(v)` / `Option.None` in expressions.

### Error Propagation

```inko
fn pub multi_step() -> Result[String, String] {
  let first = try step_one
  step_two(first)
}
```

Or, when you need to inspect the error:

```inko
fn pub multi_step() -> Result[String, String] {
  match step_one {
    case Ok(result) -> match step_two(result) {
      case Ok(final) -> Result.Ok(final)
      case Error(e) -> Result.Error(e)
    }
    case Error(e) -> Result.Error(e)
  }
}
```

**Note:** Inko doesn't have try-catch or the `?` operator. Use `try` with
`Result` types, or pattern matching when the error needs to be handled.
