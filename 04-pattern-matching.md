# Pattern Matching

## Let Destructuring (NEW in 0.19.1)

```inko
# Tuple destructuring in let bindings
let (name, age) = ('Alice', 42)

# Array destructuring (array patterns are non-exhaustive, so `else` is required)
let [first, second] = [10, 20] else panic("expected two values")

# Pattern with else (required for non-exhaustive patterns)
let Some(value) = optional else {
  panic("Expected Some value")
}
```

**Key points:**

- Tuple patterns are exhaustive; **array** patterns are not (the array could be
  longer or shorter), so they always need an `else`
- Non-exhaustive patterns require an `else` branch that diverges
- The `else` branch must use `panic`, `return`, `throw`, etc. — it can't produce
  a fallback value

## Matching Options

```inko
match optional_value {
  case Some(v) -> v.to_string
  case None -> "default"
}
```

## Matching Results

```inko
match result_value {
  case Ok(v) -> v
  case Error(e) -> panic("Error: ${e}")
}
```

## Matching with Guards

```inko
match number {
  case n if n > 0 -> "positive"
  case n if n < 0 -> "negative"
  case _ -> "zero"
}
```

## Matching HTTP Paths (Array Patterns)

```inko
impl Handle for MyApp {
  fn pub mut handle(request: mut Request) -> Response {
    match request.target {
      case [] -> Response.new.string("Home")
      case ["health"] -> Response.new.string("OK")
      case ["api", "users"] -> Response.new.string("Users")
      case ["api", "users", id] -> Response.new.string("User ${id}")
      case _ -> Response.not_found
    }
  }
}
```

## Array Destructuring

Array patterns match an **exact** size. Variable-size patterns such as
`[first, second, ..rest]` aren't supported:

```inko
match values {
  case [first, second] -> {
    # Exactly two elements
  }
  case [single] -> {
    # Exactly one element
  }
  case [] -> {
    # Empty array
  }
  case _ -> {
    # Three or more elements
  }
}
```

To get at the remaining elements, use `Array.split_first`/
`Array.split_last` or `Array.slice`.

## Class Literal Patterns

Match against class instances using field patterns:

```inko
type Person {
  let @name: String
  let @age: Int
}

match person {
  case { @name = "Alice", @age = age } -> "Alice is ${age}"
  case { @age = 18 } -> "Just turned 18"  # Other fields wildcarded
  case _ -> "Someone else"
}
```

**Key points:**

- Omitted fields are treated as wildcards
- Can bind fields to variables or match against literals
- Particularly useful for destructuring complex types

## OR Patterns

Combine multiple patterns with `or`:

```inko
match value {
  case 10 or 20 or 30 -> "Found a match"
  case "foo" or "bar" -> "String match"
  case _ -> "No match"
}
```

## Nested Patterns

Patterns can be nested arbitrarily deep:

```inko
match result {
  case Ok(Some((name, age))) -> "Got ${name}, age ${age}"
  case Ok(None) -> "No data"
  case Error(e) -> "Error: ${e}"
}
```

## Pattern Matching Performance

**Enum variants:** Compiled to jump tables -> O(1) performance regardless of variant count

**Literals/Constants:** Compiled to if/else chains -> O(n) for n patterns

**Class patterns:** Direct field access -> O(1)

## Important: Match Uses `->` Not `=>`

```inko
# WRONG (pre-release syntax)
match value {
  case Ok(v) => "success"
}

# CORRECT (0.20.0)
match value {
  case Ok(v) -> "success"
}
```
