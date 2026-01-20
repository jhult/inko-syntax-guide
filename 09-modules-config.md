# Imports, Modules, and Configuration

## Constants

Inko supports two types of variables using the `let` keyword: local variables and constants.

### Defining Constants

Constants are defined similar to local variables, except their names start with a capital letter:

```inko
let NUMBER = 42
let MAX_SIZE = 1024
let API_VERSION = "v1"
```

**Key characteristics:**

- Constant names must start with a capital letter
- Constants can never be assigned a new value (compile-time error if you try)
- Constants can only be defined outside of methods and classes (at module level)
- Constants are permanent values and are never dropped

**Example:**

```inko
# Module-level constant definition
let PORT = 3000
let DEFAULT_TIMEOUT = 30

type MyApp {}

impl MyApp {
  fn pub static new -> MyApp {
    MyApp()
  }
}

# This would be a compile-time error:
# PORT = 8080  # Error: cannot assign to constant
```

### Constants vs Local Variables

**Local variables** (lowercase names, can be mutable):

```inko
let number = 42
let mut count = 0  # Mutable local variable

count = 1  # OK: local variables with 'mut' can be reassigned
number = 50  # ERROR: immutable local variables cannot be reassigned
```

**Constants** (uppercase names, always immutable):

```inko
let NUMBER = 42

# ERROR: constants can never be reassigned
NUMBER = 50
```

---

## Package Management: `inko.pkg` (IMPORTANT)

**Critical:** The official Inko package manifest file is `inko.pkg`, NOT `package.inko`. The `package.inko` format does not exist in the official Inko documentation.

**Correct format (`inko.pkg`):**

```inko
# inko.pkg - This is the ONLY valid package manifest filename
# Comments start with #

# require URL VERSION CHECKSUM
require gitlab.com/bob/http 1.0.1 ece1027ada626bddd1efc74ba88a87dbdc19522c
```

**Syntax:**

- Each line is either a comment (starts with `#`) or a `require` command
- `require URL VERSION CHECKSUM`
- `URL` can be any Git URL (including local file paths)
- `VERSION` is `MAJOR.MINOR.PATCH` format
- `CHECKSUM` is SHA1 of the Git commit

**Package naming rules:**

- Package names should contain only letters, numbers, and underscores
- Can prefix with `inko-` (e.g., `inko-http`) for clarity
- The `inko-` prefix is automatically stripped when importing
- Package names with hyphens (except the `inko-` prefix) cannot be imported

**Sources:**

- [Package management - Inko manual](https://docs.inko-lang.org/manual/latest/guides/packages/)

### Local Path Dependencies

Inko allows referencing local projects with relative paths in `inko.pkg`:

```inko
require ../local-package 0.1.0 <commit-sha>
```

**Key points:**

- Use relative paths like `../local-package`
- Must include valid commit SHA1 checksum
- Useful for developing multiple related packages
- Can switch to Git URL when publishing to GitHub

**To get commit SHA1:**

```bash
git log -1 --format='%H'
```

### Package CLI Commands

**Official Documentation:** [https://docs.inko-lang.org/manual/latest/guides/packages/](https://docs.inko-lang.org/manual/latest/guides/packages/)

Inko uses **minimal version selection (MVS)** - it selects the highest version that satisfies all stated requirements, not the latest releases. This means no lock file is needed.

```bash
# Add a package to inko.pkg
inko pkg add github.com/user/package 1.2.3

# Synchronize dependencies (downloads and installs to ./dep)
inko pkg sync

# Update packages to newer versions within same major version
inko pkg update

# Update packages including major version changes
inko pkg update --major

# Remove a package from inko.pkg
inko pkg remove github.com/user/package
```

**Key points:**

- The `./dep` directory should be added to `.gitignore`
- After modifying `inko.pkg`, run `inko pkg sync`
- MVS means you won't accidentally use untested versions

### Publishing Packages

To publish a package:

1. Push your repository to a Git host (GitHub, GitLab, etc.)
2. Create a tag formatted as `v[VERSION]` (e.g., `v1.0.0`, `v3.8.5`)
3. Others can then add your package with `inko pkg add`

**Package naming:**

- Use the `inko-` prefix for clarity (e.g., `inko-http`)
- The compiler strips this prefix during imports
- Example: `github.com/user/inko-http` -> import as `http`

---

## Imports

### Import Entire Module

```inko
import std.env
import std.net.http.server
```

### Import Specific Symbols

```inko
import std.int (Int, Format)
import std.net.http.server (Handle, Request, Response, Server)
```

**Key points:**

- Use parentheses to list specific symbols: `import std.module (Symbol1, Symbol2)`
- This is preferred for clarity and to avoid namespace pollution

### Using Imported Symbols

```inko
# When imported with (Symbol)
let x = Int.parse("123", format: Format.Decimal)

# When importing entire module
let x = std.int.Int.parse("123", format: std.int.Format.Decimal)
```

### Module Structure

```inko
# File: src/http/server.inko
# Module: http.server

# Import in another file
import http.server (Server)

# Or import entire module
import http.server
```

### Various Import Forms

```inko
# Import entire module
import std.net.http

# Import specific symbols
import std.net.http (Server, Client)

# Import with alias
import std.net.http (Server as HttpServer)

# Multiple imports
import std.fs (file, path)
import std.io (Read, Write)
```

### Module Name Resolution

**Module names match directory structure:**

- File: `src/email/parser.inko`
- Module name: `email.parser`
- Import: `import email.parser (ParsedEmailMessage, EmailParser)`

---

## Configuration

### Reading Environment Variables

```inko
import std.env

fn pub get_config -> String {
  match env.get("MY_VAR") {
    case Ok(v) -> v
    case _ -> "default_value"
  }
}
```

**Key points:**

- `env.get()` returns `Result[String, MissingVariable]`

### Parsing Integers from Strings

```inko
import std.int (Int, Format)

fn pub parse_port(port_str: String) -> Int {
  match Int.parse(port_str, format: Format.Decimal) {
    case Some(p) -> p
    case None -> 3000  # default
  }
}
```

**Key points:**

- `Int.parse()` takes two args: string and `format: Format.Decimal`
- `Int.parse()` returns `Option[Int]` (not Result!)
- Import `Format` from `std.int`, NOT `std.fmt`

### Command-Line Arguments

```inko
import std.env (arguments)
import std.stdio (Stdout)

type async Main {
  fn async main {
    let out = Stdout.new
    let args = arguments

    out.print("Arg count: ${args.size}")

    for arg in args {
      out.print("  arg: ${arg}")
    }
  }
}
```

**Key points:**

- `arguments` returns `Array[String]`
- Args include the program arguments, NOT the program name itself
- Import `arguments` from `std.env`

---

## Modules and Top-Level Code

**Valid at top-level:**

- Import statements
- Constants (names starting with capital letters)
- Type definitions (classes, enums, traits)
- Method definitions
- Trait implementations

**NOT valid at top-level:**

- Local variables (lowercase `let` or `let mut`)
- Expressions (except method bodies)
- Statements outside methods

```inko
# OK - constants at module level
import std.stdio (Stdout)

let MAX_SIZE = 1024
let PORT = 3000

type MyClass {}

# NOT OK - will cause compile error
let x = 42  # Local variables not allowed at top-level
```
