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
  version: 2.2.0
---

# Inko Language Skill

Inko is a statically-typed language with unique syntax that differs significantly from Rust, Python, and Go. LLM training data for Inko is sparse, so guessing syntax from other languages causes compile errors. This skill embeds the most critical rules and common stdlib patterns inline so you can generate correct Inko without fetching external references for most tasks.

## Critical Syntax Rules (inline, do not fetch)

These are the rules that most often cause compile errors. Violating any of these produces a compile-time error.

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
| `var @field: Type` | `let mut @field: Type` | Mutable fields use `let mut`, not `var` |
| `println(x)` | `out.print("${x}\n")` or `out.write(...)` | No `println` — use `Stdout.new` |
| `UInt8` / `UInt16` / etc. | `Uint8` / `Uint16` / etc. | FFI types use lowercase `int` (0.20.0 breaking change) |

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
# Regular heap type with immutable field
type pub MyType { let @field: Type }

# Regular heap type with mutable field
type pub Counter { let mut @count: Int }

# Stack-allocated (small types, value-like)
type inline pub Point { let @x: Int, let @y: Int }

# Atomically reference-counted (shared immutable with String fields, NEW 0.20.0)
type ref pub SharedConfig { let @name: String, let @version: Int }

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

## I/O Patterns (inline, most programs need these)

Inko does not have `println`, `print`, `stdin.read_line()`, or other convenience functions found in most languages. All I/O goes through typed objects.

```inko
import std.stdio (Stdin, Stdout)
import std.io (BufferedReader)
import std.bytes (ByteArray)

type async Main {
  fn async main {
    let out = Stdout.new
    let inp = BufferedReader.new(Stdin.new)
    let buf = ByteArray.new

    # Print output
    out.print("Hello, World!")        # Appends newline
    out.write("no newline here")     # No newline

    # Read lines from stdin until EOF
    loop {
      buf.clear
      let n = try inp.read_line(into: buf, inclusive: false) else (_) {
        return
      }
      if n == 0 { break }             # EOF: 0 bytes read
      let line = buf.to_string
      # process line...
    }
  }
}
```

## Common stdlib Method Names (inline)

These differ from what you'd expect from other languages. Using the wrong name causes a compile error.

| What you want | Inko method | Notes |
|--------------|-------------|-------|
| Map insert | `map.set(key, value)` | Not `insert` — returns `Option[V]` |
| Map lookup | `map.get(key)` | Returns `Result[ref V, MissingKey]`, not `Option` |
| Map contains | `map.contains?(key)` | Predicate methods end with `?` |
| Map iterate | `for (k, v) in map.iter {}` | Yields `(ref K, ref V)` tuples |
| String lowercase | `s.to_lower` | Not `to_lowercase()` — no parens, it's a field |
| String uppercase | `s.to_upper` | Same pattern |
| String split | `s.split(",")` | Returns `Stream[Slice[String]]` — iterate with `for` |
| String trim | `s.trim` | Not `trim()` — it's a field |
| String contains | `s.contains?("sub")` | Predicate method |
| String size | `s.size` | Byte size, not character count |
| String replace | `s.replace("old", "new")` | Returns new String |
| Array sort | `arr.sort` | Requires `T: Compare` |
| Array sort custom | `arr.sort_by fn (a, b) { ... }` | Closure returns `Ordering` |
| Array push | `arr.push(value)` | Appends to end |
| Array size | `arr.size` | Number of elements |
| Read file | `File.new(path).or_panic(...)` | Returns `Result[File, Error]` |
| JSON build | `Json.object.string('k', v).into_string` | Builder pattern, not manual Map |
| JSON array | `Json.array.string('a').into_string` | Array builder pattern |
| Structured log | `Logger.new(out).info("msg")` | `import std.log (Logger)` |
| Gzip encode | `Encoder.new.compress(data)` | `import std.compress.gzip (Encoder)` |
| Atomic bool | `AtomicBool.new(false)` | `import std.sync (AtomicBool)` |
| Atomic int | `AtomicInt.new(0)` | `import std.sync (AtomicInt)` |

## Common Import Patterns

```inko
import std.net.http.server (Handle, Request, Response, Server)
import std.fs.file (File)
import std.io (Read, Write, BufferedReader)
import std.json (Json)
import std.env
import std.env (arguments)
import std.int (Int, Format)
import std.time.duration (Duration)
import std.test (Tests)
import std.string (StringBuffer, ToString)
import std.bytes (ByteArray, Bytes, ToSlice)
import std.map (Map)
import std.array (Array)
import std.cmp (Compare, Ordering)
import std.sync (Promise, AtomicBool, AtomicInt)
import std.log (Logger)
import std.compress.gzip (Encoder)
```

## Syntax Guide (fetch only for domain-specific questions)

**Base URL:** `https://raw.githubusercontent.com/jhult/inko-syntax-guide/trunk/`

The inline rules above cover syntax correctness and common stdlib patterns for most code generation. Only fetch additional files when you need domain-specific API details that aren't covered inline.

**Do not fetch docs.inko-lang.org or browse the web for Inko documentation** — the syntax guide files below are the authoritative reference and will save you time.

| File | Fetch When |
|------|-----------|
| `12-gotchas.md` | Debugging compile errors the inline rules didn't prevent |
| `02-types-memory.md` | Choosing between `type` / `type inline` / `type copy`, ownership patterns, `recover` |
| `04-pattern-matching.md` | Complex destructuring, guards, OR patterns |
| `05-error-handling.md` | Designing custom error types, `try`/`throw` patterns |
| `06-concurrency.md` | Writing async processes, message passing, Promises |
| `07-data-types.md` | Detailed String/Array/Option/Result/ByteArray/Slice operations |
| `10-networking.md` | HTTP servers, TCP clients, WebSockets |
| `17-ffi.md` | Calling C code from Inko |
| `18-checklist.md` | Pre-commit verification checklist |

Other files (`01-quick-reference.md`, `03-methods-functions.md`, `08-control-flow.md`, `09-modules-config.md`, `11-syntax-patterns.md`, `13-best-practices.md`, `14-testing.md`, `15-stdlib.md`, `16-advanced.md`) are available if needed but the inline content above covers their most common patterns.

### How to Fetch

```bash
curl -s "https://raw.githubusercontent.com/jhult/inko-syntax-guide/trunk/12-gotchas.md"
```

## Build Commands

```bash
# Debug build (fast compile, for development)
inko build src/main.inko

# Release build (optimized)
inko build --release src/main.inko

# Cross-compile for Linux x86_64 (requires Zig)
inko build --release --target amd64-linux-gnu --linker zig src/main.inko
```

Build output: Debug → `build/debug/`, Release → `build/release/`, Cross-compiled → `build/<target>/`

**Container image (Inko 0.20.0):** `ghcr.io/inko-lang/inko@sha256:fa5aad694709c95e7e9abe3fd290f71ec62f1b4e2b230fad8b56b6b64617052e`

Use this image in CI or local Docker environments to ensure a consistent Inko toolchain.

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

1. **Read existing source** — understand patterns already in the project before adding new code
2. **Write code** — following the critical syntax rules and stdlib patterns above
3. **Format check** — `inko fmt --check src/ test/`
4. **Build** — `inko build src/main.inko` (catches compile errors)
5. **Test** — `inko test`
6. **Fetch `12-gotchas.md`** if hitting unexpected compile errors

## Anti-Patterns

- Writing Inko without consulting this skill — incorrect syntax from other languages is the #1 error source
- Using `class`, `self.`, `+=`, `=>`, `&&`, `||`, `Type<T>`, `&mut`, `.unwrap()`, `?`, `var @field`, `println()`, `UInt8`/`UInt16`/`UInt32`/`UInt64` — all from other languages or pre-0.20.0, none compile
- Guessing stdlib method names — use the table above (`Map.set` not `insert`, `to_lower` not `to_lowercase()`, etc.)
- Forgetting that `Array.get` and `Map.get` return `Result`, not `Option` — pattern match with `Ok`/`Error`
- Using `Some(x)` or `None` as expressions — they must be `Option.Some(x)` and `Option.None`
- Using `Ok(x)` or `Error(e)` in match patterns — they must be `case Ok(v)` / `case Error(e)` (unqualified)
- Browsing docs.inko-lang.org — the syntax guide files are faster and more targeted
- Fetching syntax guide files for simple code — the inline rules suffice for most tasks