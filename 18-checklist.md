# For LLMs: Code Generation Checklist

Before outputting Inko code, verify each item:

## Syntax Verification

- [ ] **Type keyword**: Using `type` not `class` or `struct`
- [ ] **Match arrows**: Using `->` not `=>`
- [ ] **Field access**: Using `@field` not `self.field`
- [ ] **No self parameter**: Methods don't have explicit `self` in signature
- [ ] **Method modifiers order**: `fn pub static` or `fn pub mut` (pub after fn)
- [ ] **Assignment**: `x = x + 1` and `x += 1` are both valid (`+=`, `-=`, `*=`, `/=`, `%=` exist)
- [ ] **Logical operators**: Using `and`/`or` not `&&`/`||`
- [ ] **Negation**: Using `!x` (there is no `not` keyword)

## Type System Verification

- [ ] **Array access**: `.get(i)` returns `Result[ref T, ...]`, not `Option`. Use `.clone` for owned copies of non-value types.
- [ ] **Option/Result in match**: Using `case Some(v)` and `case None` in match **patterns**, but `Option.Some(x)` and `Option.None` as **expressions**
- [ ] **Return statements**: Always write `Result.Ok(x)` / `Result.Error(e)`; bare `Ok`/`Error` only work as patterns
- [ ] **Generic syntax**: Using `Type[T]` not `Type<T>`
- [ ] **Mutable fields**: Using `let mut @field` for mutable fields
- [ ] **Clone for custom types**: `impl Clone for X` needed for `type inline` and regular `type` if you need `.clone`

## Error Handling Verification

- [ ] **Fallible methods**: Returning `Result[T, E]` and using `throw E` (there is no `!!` syntax)
- [ ] **Error propagation**: Using `try operation` not `operation?`
- [ ] **Panic on error**: Using `.or_panic` / `.or_panic_with("msg")` not `.unwrap()` (there is no `try!`)
- [ ] **Error handling**: Pattern matching on `Result` when the error must be handled locally (there is no `try ... else`)

## Common Patterns Verification

- [ ] **Constructors**: `fn pub static new(...) -> TypeName { TypeName(...) }`
- [ ] **HTTP handler**: Implementing `Handle` trait with `fn pub mut handle(request: mut Request) -> Response`
- [ ] **Main entry**: `type async Main { fn async main { ... } }`
- [ ] **Test entry**: `fn pub tests(t: mut Tests) { ... }` (NOT async Main)

## Memory and Ownership

- [ ] **References**: Using `ref T` and `mut T` not `&T` and `&mut T`
- [ ] **Unique values**: Using `uni T` and `recover { }` for process-safe values
- [ ] **Cloning**: Using `.clone` to copy owned values when needed
- [ ] **Parameter mut**: `param: mut Type` for mutable references; `mut param: Type` is invalid syntax
- [ ] **@field in fn mut**: Accessing `@field` in `fn mut` methods returns `mut T` — use `.clone` or extract fields for owned copies

## Before Finalizing

1. Re-read the [Quick Reference](01-quick-reference.md) section
2. Check against [Common Gotchas](12-gotchas.md) table
3. Verify all imports use correct module paths (`std.module (Symbol)`) — no nested paths like `std.io.Error` in type annotations
4. Ensure field names are prefixed with `@` inside methods
5. Verify no `(-x)` unary negation — use `0 - x` instead
6. Verify `read_line` EOF handling checks `Ok(0)`, not `Error`

---

## Quick Syntax Reference Card

| Concept | Inko Syntax |
|---------|-------------|
| Type definition | `type pub MyType { let @field: Type }` |
| Constructor | `fn pub static new(...) -> MyType { MyType(...) }` |
| Instance method | `fn pub method_name -> ReturnType { ... }` |
| Mutable method | `fn pub mut method_name -> ReturnType { ... }` |
| Static method | `fn pub static method_name -> ReturnType { ... }` |
| Async method | `fn pub async method_name(promise: uni Promise[T], ...) { ... }` |
| Field access | `@field_name` |
| Pattern match | `match value { case X -> ... }` |
| Option | `Option.Some(x)` / `Option.None` |
| Result | `Result.Ok(x)` / `Result.Error(e)` |
| Error handling | `try operation` / `match result { ... }` / `.or_panic` |
| For loop | `for item in collection { ... }` |
| Infinite loop | `loop { ... }` |
| Import | `import std.module (Symbol1, Symbol2)` |
| Trait impl | `impl TraitName for TypeName { ... }` |
| Generic type | `type pub MyType[T] { let @data: T }` |
| References | `ref T` (immutable) / `mut T` (mutable) / `uni T` (unique) |

## Common Mistakes to Avoid

| Wrong | Correct |
|-------|---------|
| `class Foo {}` | `type Foo {}` |
| `case X => ...` | `case X -> ...` |
| `fn foo(self, x: Int)` | `fn foo(x: Int)` |
| `self.field` | `@field` |
| `not x` | `!x` |
| `&&` / `\|\|` | `and` / `or` |
| `arr[0]` | `arr.get(0)` |
| `pub fn foo()` | `fn pub foo()` |
| `.unwrap()` | `.or_panic` / `.or_panic_with("msg")` |
| `operation?` | `try operation` |
| `fn f() !! Error` | `fn f() -> Result[T, Error]` + `throw` |
| `try! operation` | `operation.or_panic` |
| `for i in 0..10` | `for i in 0.until(10)` |
| `Type<T>` | `Type[T]` |
| `&T` / `&mut T` | `ref T` / `mut T` |
