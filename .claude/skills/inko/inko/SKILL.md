---
name: inko
description: >-
  Skill for writing, reading, building, testing, and debugging Inko code. Use
  this skill whenever working with .inko files, the Inko programming language,
  Inko build or test commands, or any task involving Inko syntax, types,
  concurrency, error handling, or FFI. Also use when the user mentions Inko,
  asks about the inko-syntax-guide, or needs help with any Inko-related
  operation — even if they don't explicitly say "Inko" but are working in a
  project with .inko source files. Inko is niche and its syntax differs
  significantly from Rust/Python/Go, so always consult this skill to prevent
  compile errors from incorrect syntax guesses.
license: MIT
domain: programming-language
role: specialist
scope: development
output-format: commands
metadata:
  author: jhult
  version: 2.0.0
---

# Inko Language Skill

Inko is a statically-typed language with unique syntax that differs significantly from Rust, Python, and Go. LLM training data for Inko is sparse, so guessing syntax from other languages causes compile errors. This skill embeds the most critical rules inline and provides a fetch system for deeper reference.

## Critical Syntax Rules (embed, do not fetch)

These are the rules that most often cause compile errors when generating Inko code. Violating any of these produces a compile-time error — not a runtime one.

| Wrong (from other languages) | Correct (Inko) | Why it's wrong |
|-------------------------------|-----------------|----------------|
| `class Foo {}` | `type Foo {}` | No `class` keyword |
| `case X => ...` | `case X -> ...` | Match uses `->`, not `=>` |
| `fn foo(self, x: Int)` | `fn foo(x: Int)` | `self` is implicit |
| `self.field` | `@field` | Field access uses `@` |
| `x += 1` | `x = x + 1` | No compound assignment |
| `&&` / `||` | `and` / `or` | Logical operators are words |
| `arr[0]` | `arr.get(0)` | Array indexing returns `Result[ref T, ...]` |
| `pub fn foo()` | `fn pub foo()` | `pub` goes after `fn` |
| `.unwrap()` | `.or_panic("msg")` | No `unwrap` method |
| `operation?` | `try operation` | No `?` operator |
| `Type<T>` | `Type[T]` | Generics use `[]` |
| `&T` / `&mut T` | `ref T` / `mut T` | No ampersand references |
| `(-x)` | `0 - x` | Parenthesized negation is invalid |
| `case Option.Some(v)` | `case Some(v)` | Patterns use unqualified names |
| `let x = Some(42)` | `let x = Option.Some(42)` | Expressions use qualified names |
| `mut param: Type` | `param: mut Type` | Mutable ref vs rebindable local |
| `Result[T, std.io.Error]` | `import std.io (Error)` then `Result[T, Error]` | No nested paths in type annotations |

## Method Signature Patterns

```inko
# Static constructor
fn pub static new(arg: Type) -> Self { ... }

# Instance method (immutable)
fn pub method_name -> ReturnType { ... }

# Instance method (mutable)
fn pub mut method_name -> ReturnType { ... }

# Async method
fn async pub method_name -> ReturnType { ... }

# Fallible method (can throw)
fn pub operation !! ErrorType -> SuccessType { ... }
```

## Essential Type Patterns

```inko
# Regular heap type
type pub MyType { let @field: Type }

# Stack-allocated (small types, value-like)
type inline pub Point { let @x: Int, let @y: Int }

# Enum/ADT
type enum pub Status { case Active, case Inactive }

# Process type (concurrency — each instance is a separate process)
type async pub Worker { let @id: Int }

# Entry point
type async Main {
  fn async main { ... }
}
```

## Error Handling Patterns

```inko
# Propagate error (like Rust's ?)
let value = try may_fail()

# Handle error explicitly
let value = try may_fail() else (error) { return default }

# Panic on error (use sparingly)
let value = try! may_fail()
```

## Common Import Patterns

```inko
import std.net.http.server (Handle, Request, Response, Server)
import std.fs.file (File)
import std.io (Read, Write)
import std.json (Json)
import std.env
import std.env (arguments)
import std.int (Int, Format)
import std.time.duration (Duration)
import std.test (Tests)
import std.string (StringBuffer, ToString)
import std.bytes (ByteArray, Bytes, ToSlice)
import std.sync (Promise)
```

## Syntax Guide (fetch for deeper reference)

**Base URL:** `https://raw.githubusercontent.com/jhult/inko-syntax-guide/trunk/`

The critical rules above cover most day-to-day code generation. Fetch additional files when working in specific domains:

| File | Fetch When |
|------|-----------|
| `01-quick-reference.md` | Writing any non-trivial Inko code (comprehensive syntax table) |
| `12-gotchas.md` | Debugging compile errors or writing complex code |
| `02-types-memory.md` | Designing type hierarchies, choosing `type` vs `type inline` vs `type copy` |
| `03-methods-functions.md` | Writing methods with non-standard signatures |
| `04-pattern-matching.md` | Complex destructuring, guards, OR patterns |
| `05-error-handling.md` | Designing error types, try/throw patterns |
| `06-concurrency.md` | Writing async processes, message passing, Promises |
| `07-data-types.md` | String/Array/Option/Result operations, slicing |
| `08-control-flow.md` | Loops, iteration, breaking/returning |
| `09-modules-config.md` | Package structure, imports, constants, configuration |
| `10-networking.md` | HTTP servers, TCP clients, WebSockets |
| `11-syntax-patterns.md` | Comments, closures, operators, string interpolation |
| `13-best-practices.md` | Performance, StringBuffer, type modifier selection |
| `14-testing.md` | Writing unit tests with `std.test` |
| `15-stdlib.md` | Standard library module reference and import patterns |
| `16-advanced.md` | Traits, iterators, advanced patterns |
| `17-ffi.md` | Calling C code from Inko |
| `18-checklist.md` | Pre-commit verification checklist |

### How to Fetch

```bash
curl -s "https://raw.githubusercontent.com/jhult/inko-syntax-guide/trunk/01-quick-reference.md"
```

## Build Commands

```bash
# Debug build (fast compile, for development)
inko build src/main.inko

# Release build (optimized)
inko build --release src/main.inko

# Cross-compile for Linux x86_64 (requires Zig)
inko build --release --target amd64-linux-gnu --linker zig src/main.inko

# Cross-compile for Linux ARM64
inko build --release --target arm64-linux-gnu --linker zig src/main.inko

# Cross-compile for Linux x86_64 musl
inko build --release --target amd64-linux-musl --linker zig src/main.inko
```

Build output: Debug → `build/debug/`, Release → `build/release/`, Cross-compiled → `build/<target>/`

## Test and Format Commands

```bash
# Run unit tests
inko test

# Format check (no changes)
inko fmt --check src/ test/

# Format and apply changes
inko fmt src/ test/
```

## Standard Workflow

1. **Fetch syntax files** if writing non-trivial code — at minimum `01-quick-reference.md`, and `12-gotchas.md` if hitting compile errors
2. **Read existing source** — understand patterns already in the project before adding new code
3. **Write code** — following the critical syntax rules above
4. **Format check** — `inko fmt --check src/ test/`
5. **Build** — `inko build src/main.inko` (catches compile errors)
6. **Test** — `inko test`
7. **Verify against checklist** — fetch `18-checklist.md` and check each item before finalizing

## Anti-Patterns

- Writing Inko without consulting this skill or the syntax guide — incorrect syntax from other languages is the #1 error source
- Skipping `inko fmt --check` before committing
- Using `class`, `self.`, `+=`, `=>`, `&&`, `||`, `Type<T>`, `&mut`, `.unwrap()`, `?` — these are all from other languages and will not compile
- Guessing import paths — use the common import patterns above or fetch `15-stdlib.md`
- Forgetting that `Array.get` returns `Result[ref T, ...]`, not `Option[T]` — always pattern match with `Ok`/`Error`
- Using `Some(x)` or `None` as expressions — they must be `Option.Some(x)` and `Option.None`
- Using `Ok(x)` or `Error(e)` in match patterns — they must be `case Ok(v)` / `case Error(e)` (unqualified)