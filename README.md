# Inko 0.20.0 Syntax Guide

A comprehensive guide to Inko 0.20.0 syntax and patterns, learned from building Inko projects. This guide focuses on commonly used patterns, gotchas, and best practices.

**Inko Version:** 0.20.0
**LLVM Support:** Versions 18-21
**Last Updated:** April 22, 2026

---

## How to Use This Guide (For LLMs)

**START HERE:** Read files in order. File `01-quick-reference.md` contains critical syntax rules that MUST be followed.

## Files in This Guide

| File | Description |
|------|-------------|
| [01-quick-reference.md](01-quick-reference.md) | **CRITICAL** - Read this first. Essential syntax rules and common mistakes. |
| [02-types-memory.md](02-types-memory.md) | Type definitions, type modifiers (inline, copy, enum, async), memory management |
| [03-methods-functions.md](03-methods-functions.md) | Methods, functions, static vs instance methods, visibility |
| [04-pattern-matching.md](04-pattern-matching.md) | Pattern matching, destructuring, guards, OR patterns |
| [05-error-handling.md](05-error-handling.md) | Error handling with try/throw, Result type patterns |
| [06-concurrency.md](06-concurrency.md) | Processes, async/await, message passing, Promises |
| [07-data-types.md](07-data-types.md) | Strings, Arrays, Option, Result, slicing |
| [08-control-flow.md](08-control-flow.md) | Loops, iteration, mutability and borrowing |
| [09-modules-config.md](09-modules-config.md) | Imports, modules, package management, constants, configuration |
| [10-networking.md](10-networking.md) | HTTP server, TCP client, WebSockets |
| [11-syntax-patterns.md](11-syntax-patterns.md) | Additional syntax: comments, closures, operators, strings |
| [12-gotchas.md](12-gotchas.md) | **IMPORTANT** - Common mistakes that cause compile errors |
| [13-best-practices.md](13-best-practices.md) | Best practices and performance considerations |
| [14-testing.md](14-testing.md) | Unit testing with std.test |
| [15-stdlib.md](15-stdlib.md) | Standard library reference |
| [16-advanced.md](16-advanced.md) | Advanced patterns, traits, iterators, tips |
| [17-ffi.md](17-ffi.md) | Foreign Function Interface (FFI) for calling C code |
| [18-checklist.md](18-checklist.md) | Code generation checklist for verification |

---

## Resources

- [Inko 0.19.1 Release Notes](https://inko-lang.org/news/inko-0-19-1-is-released/)
- [Inko Manual](https://docs.inko-lang.org/manual/latest/)
- [Inko Standard Library](https://docs.inko-lang.org/std/main/)
- [Inko Community](https://inko-lang.org/community/)
