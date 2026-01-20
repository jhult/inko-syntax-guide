# Methods and Functions

## Public vs Private

```inko
# Public method
fn pub static public_method(input: String) -> String {
  input
}

# Private method (no pub keyword)
fn private_method(input: String) -> String {
  input
}
```

**Important**: Never use `pub pub` - this is a syntax error.

## Instance Methods

```inko
impl Person {
  # Method that modifies internal state
  fn pub mut set_email(email: String) {
    @email = email
  }

  # Method that doesn't modify state
  fn pub get_name -> String {
    @name
  }

  # Method that returns owned copy
  fn pub name_copy -> String {
    @name.clone
  }
}
```

**Key points:**

- Use `fn pub mut` for methods that modify internal state
- Use `fn pub` for methods that don't modify state
- **NO explicit `self` parameter needed** - it's implicit!
- Access fields with `@field_name`
- Use `.clone` to return owned copies of fields

## Static Methods

```inko
impl Person {
  fn pub static from_name(name: String) -> Person {
    Person.new(name, age: 0)
  }
}
```

## Method Parameters - CRITICAL

```inko
# WRONG - Never add explicit self parameter
fn pub get_value(self: Person) -> String {
  @name
}

# CORRECT - self is implicit
fn pub get_value -> String {
  @name
}

# WRONG - Never add self to parameter list
fn pub mut process(mut self, input: String) -> String {
  # ...
}

# CORRECT - mut before method name, parameters only
fn pub mut process(input: String) -> String {
  # ...
}
```

## Method Modifiers Order

The correct order of method modifiers is:

```inko
fn pub static new(...)        # Static constructor
fn pub method_name(...)       # Public instance method (immutable)
fn pub mut method_name(...)   # Public instance method (mutable)
fn async pub method_name(...) # Async public method
fn async pub mut method(...)  # Async mutable public method
```

## Visibility Rules

**Default visibility:**

- Types and methods are private to their module by default
- Must use `pub` to make them public

**Important gotcha:**

```inko
# Private type
type Internal {}

# ERROR: Can't have public method on private type in public API
fn pub static get_internal -> Internal {  # Compile error!
  Internal()
}

# OK: Private method can return private type
fn static get_internal -> Internal {
  Internal()
}
```

**Private types can have public methods** for implementing public traits:

```inko
trait pub Display {
  fn pub to_string -> String
}

type Internal {}

impl Display for Internal {
  fn pub to_string -> String {  # OK - implementing public trait
    "internal"
  }
}
```

## Method Naming Conventions

**Predicate methods** end with `?`:

```inko
fn pub empty? -> Bool {
  @size == 0
}

if list.empty? {
  # List is empty
}
```

**Setter methods** end with `=`:

```inko
fn pub mut name=(new_name: String) {
  @name = new_name
}

person.name = "Alice"  # Calls name= method
```
