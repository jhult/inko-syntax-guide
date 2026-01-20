# Best Practices and Performance

## Best Practices

### 1. Use StringBuffer for Concatenation

```inko
# Good
let mut buffer = StringBuffer.new
buffer.push("Hello")
buffer.push(" ")
buffer.push("World")
let result = buffer.to_string

# Avoid (O(n^2) complexity)
let result = "Hello" + " " + "World"
```

### 2. Use Result Types for Error Handling

```inko
# Good
fn pub divide(a: Int, b: Int) -> Result[Int, String] {
  if b == 0 {
    Result.Error("Division by zero")
  } else {
    Result.Ok(a / b)
  }
}

# Avoid panicking for recoverable errors
fn pub divide(a: Int, b: Int) -> Int {
  if b == 0 {
    panic("Division by zero")
  }
  a / b
}
```

### 3. Use Option for Optional Values

```inko
# Good
fn pub find(id: Int) -> Option[User] {
  match @users.get(id) {
    case Ok(user) -> Option.Some(user)
    case Error(_) -> Option.None
  }
}
```

### 4. Explicit Mutability

```inko
# Good - clear what's mutable
fn pub mut process(input: String) -> String {
  @state = @state + 1
  input
}

# Be intentional about mutability
fn pub read_only -> String {
  @value.clone
}
```

### 5. Pattern Matching Over Nested Ifs

```inko
# Good
match result {
  case Ok(value) -> # handle success
  case Error(e) -> # handle error
}

# Avoid
if result.ok? {
  let value = result.or_panic("unreachable")
  # handle success
} else {
  # handle error
}
```

### 6. Use For Loop Expressions (0.19.1)

```inko
# Good (0.19.1)
for item in collection {
  process(item)
}

for (key, value) in pairs {
  store(key, value)
}

# Old style (still works but verbose)
collection.iter.each(fn (item) { process(item) })
```

### 7. Import Specific Symbols

```inko
# Good - clear what you're using
import std.net.http.server (Handle, Request, Response)

# Avoid - namespace pollution
import std.net.http.server
```

---

## Performance Considerations

### Compilation (0.19.1 Improvements)

- Generics are specialized per type (not per "shape")
- 20-30% faster compilation times
- 10-25% smaller executable sizes
- Better code generation for complex match expressions

### String Building

- Use `StringBuffer` for concatenations in loops
- Avoid repeated `+` operations (O(n^2) complexity)
- `StringBuffer` is redesigned in 0.19.1 for better memory efficiency

### Array Operations

- Use `.slice()` for non-copying views (0.19.1)
- Avoid unnecessary clones
- Use `ByteArray` for raw byte manipulation

### Error Handling

- Use `Result` types instead of panics for recoverable errors
- Avoid deeply nested error handling
- Consider early returns with pattern matching

### Type Modifiers for Performance

Choose the right type modifier for your use case:

| Type | When to Use |
|------|-------------|
| `type` | Large types, recursive structures, trait casting |
| `type inline` | Small types, mixed value/heap, need mutability |
| `type copy` | Primitives only, completely immutable |
| `type enum` | Algebraic data types |

---

## Tips for Success

01. **Start simple** - Get a minimal example working before adding complexity
02. **Use the release notes** - The 0.19.1 announcement has great examples
03. **Embrace pattern matching** - It's the primary control flow construct
04. **Remember: no `class` keyword** - Use `type` instead
05. **Remember: no explicit `self` parameter** - It's implicit in methods
06. **Import specific symbols** - Makes code clearer and avoids conflicts
07. **Use for loop expressions** - They're cleaner than iterator methods
08. **Use `.get()` with Result** - Arrays and collections return Result, not Option
09. **Use `!` for boolean negation** - Not `.true?` or `.false?`
10. **Take advantage of slicing** - Non-copying `Slice[T]` views are efficient
11. **Use `ref` for borrowing** - `Option[ref T]` and `ref value` for references
12. **Implement traits** - Use `impl TraitName for TypeName` for interfaces
13. **Use static factory methods** - `default`, `strict`, `permissive` patterns
14. **Iterator methods are powerful** - `find_map`, `map`, `join` for transformations
15. **ByteArray for binary data** - Use `.to_byte_array` and `ByteArray.new`
16. **String API: use `.substring()` for String results, `.slice()` for Slice views**
17. **Use `.contains?()` for substring checks (predicate method)**
18. **String methods: `.index_of()` returns Option[Int]**
