# Additional Syntax Patterns

## Comments

Single-line comments use `#`:

```inko
# This is a comment
let x = 42  # Inline comment
```

**Important:** Multiple consecutive comment lines merge into one documentation comment:

```inko
# This is the first line
# This is the second line
# They merge into a single doc comment
fn pub example {}
```

## Closures

Inko supports closures with various forms:

```inko
# Simple closure
let add = fn (a: Int, b: Int) -> Int { a + b }

# Closure with no arguments
let greet = fn { "Hello!" }

# Closure with error handling (closures return Result like methods)
let may_fail = fn (x: Int) -> Result[Int, String] {
  if x < 0 {
    throw "Negative number"
  }
  Result.Ok(x * 2)
}

# Using closures
let result = add.call(10, 20)  # => 30
let msg = greet.call  # => "Hello!"
```

## The `as` Operator (Type Casting)

Cast values to different types:

```inko
let value = something as SomeType

# Has higher precedence than binary operators
let x = value as Int + 10  # Parsed as (value as Int) + 10
```

**Key points:**

- Use for upcasting to trait types
- Higher precedence than binary operators
- Runtime checked

## Operators and Precedence

**Arithmetic:** `+`, `-`, `/`, `*`, `**` (power), `%`

**Bitwise:** `<<`, `>>`, `|`, `&`, `^`, `>>>` (unsigned right shift)

**Comparison:** `<`, `>`, `<=`, `>=`, `==`, `!=`

**Logical:** `and`, `or` (note: NOT `&&` or `||`)

**Important precedence notes:**

- `and`/`or` have higher precedence than binary operators
- Use parentheses for clarity: `if (a > 10) and (b < 20)`
- Type casting (`as`) has higher precedence than binary operators

## Multi-line Strings

There is no `\` line continuation. A string literal may span multiple lines,
and the newlines are kept as-is:

```inko
let long_string = "This is a very long string
that continues on the next line
and keeps going"
```

If you don't want the newlines, concatenate with `+`:

```inko
let long_string = "This is a very long string " +
  "that continues on the next line " +
  "and keeps going"
```

## Module Aliasing

```inko
import std.string (String as StdString, ToString)

# Use aliased name to avoid conflicts
let items = StdString.join(values.into_iter, with: ' ')
```

**Key points:**

- Use `import std.module (Symbol as Alias)` for aliasing
- Useful when names would conflict with local types

## Using Duration

```inko
import std.sync (Channel)
import std.time (Duration)

# Create durations
let timeout = Duration.from_secs(1)
let short = Duration.from_millis(500)

# Timeouts are passed as deadlines, via Duration.to_instant
let queue: Channel[uni Int] = Channel.new

match queue.receive_until(timeout.to_instant) {
  case Some(value) -> # got a value
  case None -> # timed out
}
```

**Key points:**

- `Duration` lives in `std.time`, not `std.time.duration`
- Constructors are `from_secs`, `from_millis`, `from_micros`, `from_nanos`
- Timeouts are usually passed as a `ToInstant` deadline: `duration.to_instant`

## Tuple Return Values

**Inko supports tuples:**

```inko
fn pub get_counts -> (Int, Int) {
  (10, 20)
}

let (spam_hits, ham_hits) = get_counts
```

## Static Factory Methods

```inko
type pub ErrorConfig {
  let @max_errors: Int
  let @continue_on_parse_error: Bool

  fn pub static default -> ErrorConfig {
    ErrorConfig(
      max_errors: 100,
      continue_on_parse_error: true,
    )
  }

  fn pub static strict -> ErrorConfig {
    ErrorConfig(
      max_errors: 0,
      continue_on_parse_error: false,
    )
  }

  fn pub static permissive -> ErrorConfig {
    ErrorConfig(
      max_errors: 9999999,
      continue_on_parse_error: true,
    )
  }
}
```

**Key points:**

- Use `fn pub static method_name -> Type` for factory methods
- Common pattern: `default`, `strict`, `permissive` for config types

## Empty Structs Need at Least One Field

**Wrong:**

```inko
type ArbitraryDetector {}

impl ArbitraryDetector {
  fn pub static new -> ArbitraryDetector {
    ArbitraryDetector {}  # Error: can't infer type
  }
}
```

**Right:**

```inko
type ArbitraryDetector {
  let @dummy: Bool
}

impl ArbitraryDetector {
  fn pub static new -> ArbitraryDetector {
    ArbitraryDetector(dummy: true)
  }
}
```

## Type Aliases Not Supported

**Cannot create type aliases like Rust:**

**Wrong:**

```inko
type pub Email = ParsedEmailMessage  # Compile error!
```

**Workaround:** Use the original type name directly, or wrap it in a new type:

```inko
# Option 1: Use the original type directly
fn pub check(email: ref EmailMessage) -> Array[String] {
  # ...
}

# Option 2: Create a wrapper type
type pub EmailWrapper {
  let @email: EmailMessage
}
```

## No `log` or `exp` Methods on Float

**Wrong:**

```inko
let log_val = value.log
let exp_val = value.exp
```

**Right:** Implement your own or use alternative approaches:

```inko
# Use linear approximation or integer math for probabilities
# For spam classification, word frequency counting works well
```
