# Quick Reference for LLMs

> **IMPORTANT:** Read this section first when generating Inko code. Inko has unique syntax that differs significantly from Rust, Python, and other languages.

## Critical Syntax Rules (MUST Follow)

| Rule | WRONG | CORRECT |
|------|-------|---------|
| Type definitions | `class Foo {}` | `type Foo {}` |
| Match arrow | `case X => ...` | `case X -> ...` |
| Self parameter | `fn foo(self, x: Int)` | `fn foo(x: Int)` |
| Field access | `self.field` | `@field` |
| Increment | `x += 1` | `x = x + 1` |
| Logical operators | `&&` / `\|\|` | `and` / `or` |
| Array access | `arr[0]` | `arr.get(0)` (returns Result!) |
| Public visibility | `pub fn foo()` | `fn pub foo()` |
| Mutable method | `fn foo(&mut self)` | `fn pub mut foo` |
| Static method | `fn foo()` in impl | `fn pub static foo` |

## Inko is NOT Like Other Languages

**NOT like Rust:**

- No `&` or `&mut` reference syntax - use `ref T` and `mut T`
- No `?` operator - use `try` keyword or pattern matching
- No `.unwrap()` - use `.or_panic("message")` or pattern match
- No `impl Trait for Type { fn foo(&self) }` - self is implicit, use `fn pub foo`
- No `struct` - use `type`
- No `enum` - use `type enum`

**NOT like Python/JavaScript:**

- No `class` - use `type`
- No `self.field` - use `@field`
- No `+=`, `-=`, etc. - write `x = x + 1`
- No truthiness - booleans only, use explicit checks
- No exceptions - use `Result` types with `try`

**NOT like Go:**

- No `:=` for declaration (`:=` is the swap operator!)
- No `interface{}` - use traits
- No `nil` for optionals - use `Option[T]`

## Method Signature Patterns

```inko
# Static constructor (most common)
fn pub static new(arg: Type) -> Self { ... }

# Instance method (immutable)
fn pub method_name -> ReturnType { ... }

# Instance method (mutable)
fn pub mut method_name -> ReturnType { ... }

# Async method
fn async pub method_name -> ReturnType { ... }
```

## Essential Type Patterns

```inko
# Regular heap type
type pub MyType { let @field: Type }

# Stack-allocated (small types)
type inline pub Point { let @x: Int, let @y: Int }

# Enum/ADT
type enum pub Status { case Active, case Inactive }

# Process type (concurrency)
type async pub Worker { let @id: Int }
```

## Error Handling Quick Reference

```inko
# Method that can fail
fn pub operation !! ErrorType -> SuccessType { ... }

# Propagate error (like Rust's ?)
let value = try may_fail()

# Handle error explicitly
let value = try may_fail() else (error) { return default }

# Panic on error (use sparingly)
let value = try! may_fail()
```

## Complete Example: HTTP Server

```inko
import std.env
import std.int (Int, Format)
import std.net.http.server (Handle, Request, Response, Server)
import std.stdio (Stdout)

fn pub server_port -> Int {
  match env.get("PORT") {
    case Ok(v) -> match Int.parse(v, format: Format.Decimal) {
      case Some(p) -> p
      case None -> 3000
    }
    case _ -> 3000
  }
}

type MyApp {}

impl Handle for MyApp {
  fn pub mut handle(request: mut Request) -> Response {
    match request.target {
      case [] -> Response.new.string("Welcome")
      case ["health"] -> Response.new.json("{\"status\":\"healthy\"}")
      case ["api", "users"] -> Response.new.json("{\"users\":[]}")
      case _ -> Response.not_found
    }
  }
}

type async Main {
  fn async main {
    let out = Stdout.new
    let port = server_port

    out.print("Starting server on port ${port}")

    let server = Server.new(fn { recover MyApp() })

    match server.start(port) {
      case Ok(_) -> {
        out.print("Server running...")
        loop { }
      }
      case Error(e) -> panic("Failed to start: ${e}")
    }
  }
}
```
