---
name: inko
description: >-
  Skill for working with Inko projects. Use when writing, reading, building,
  or testing Inko code. Fetches the syntax guide, covers build commands, test
  workflows, and common pitfalls.
license: MIT
domain: programming-language
role: specialist
scope: development
output-format: commands
triggers:
  - inko
  - .inko
  - inko build
  - inko test
  - inko fmt
metadata:
  author: jhult
  version: 1.0.0
---

# inko — Inko Language Skill

## Critical Rules

| Rule | Why |
|------|-----|
| **Fetch syntax guide before writing code** | Inko is niche — LLM training data is sparse |
| **Read `01-quick-reference.md` first** | Critical syntax rules that prevent compile errors |
| **Read `12-gotchas.md` second** | Common mistakes that cause compile errors |
| **Use `--json` for all recalldory output** | All commands output structured JSON |

## Syntax Guide

**Base URL:** `https://raw.githubusercontent.com/jhult/inko-syntax-guide/trunk/`

### Required Reading (fetch before writing any Inko)

```
01-quick-reference.md   # Critical syntax rules — READ FIRST
12-gotchas.md           # Common mistakes that cause compile errors
```

### Additional References (fetch as needed)

```
02-types-memory.md      # Types and memory management
03-methods-functions.md # Methods and functions
04-pattern-matching.md  # Pattern matching
05-error-handling.md    # Error handling
06-concurrency.md       # Processes and async
07-data-types.md        # Strings, Arrays, Option, Result
18-checklist.md         # Code generation verification checklist
README.md               # Full index
```

### How to Fetch

```bash
# Example: fetch quick reference
curl -s "https://raw.githubusercontent.com/jhult/inko-syntax-guide/trunk/01-quick-reference.md"

# Example: fetch gotchas
curl -s "https://raw.githubusercontent.com/jhult/inko-syntax-guide/trunk/12-gotchas.md"
```

## Build Commands

```bash
# Debug build (fast, for development)
inko build src/recalldory.inko

# Release build (optimized)
inko build --release src/recalldory.inko

# Cross-compile for Linux x86_64 (requires Zig)
inko build --release --target amd64-linux-gnu --linker zig src/recalldory.inko

# Cross-compile for Linux ARM64
inko build --release --target arm64-linux-gnu --linker zig src/recalldory.inko

# Cross-compile for Linux x86_64 musl
inko build --release --target amd64-linux-musl --linker zig src/recalldory.inko
```

Build output locations:
- Debug: `build/debug/`
- Release: `build/release/`
- Cross-compiled: `build/<target>/`

## Test Commands

```bash
# Run all unit tests
inko test

# Run integration tests (bash)
bash test/integration_test.sh

# Format check (no changes)
inko fmt --check src/ test/

# Format and apply changes
inko fmt src/ test/
```

## Project Conventions

- All command output is JSON (structured, machine-readable)
- Use `--json` flag in recalldory commands
- Entry point: `src/recalldory.inko`
- Source modules: `src/recalldory/`
- Tests: `test/`

## Standard Workflow Before Writing Inko Code

```bash
# 1. Fetch required syntax files
curl -s "https://raw.githubusercontent.com/jhult/inko-syntax-guide/trunk/01-quick-reference.md"
curl -s "https://raw.githubusercontent.com/jhult/inko-syntax-guide/trunk/12-gotchas.md"

# 2. Read relevant source files first
# (understand existing patterns before adding new code)

# 3. Write code

# 4. Format check
inko fmt --check src/ test/

# 5. Build (catches compile errors)
inko build src/recalldory.inko

# 6. Test
inko test
bash test/integration_test.sh
```

## Anti-Patterns

- Writing Inko without first reading `01-quick-reference.md` and `12-gotchas.md`
- Skipping `inko fmt --check` before committing
- Running only unit tests (integration tests catch different issues)
- Guessing Inko syntax from memory — always fetch the guide
