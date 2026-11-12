# Control Flow: Loops and Mutability

## Loops and Iteration

### For Loop Expressions (0.19.1)

For loops are now expressions that support pattern matching:

```inko
# Simple iteration
for num in [10, 20, 30, 40] {
  out.print(num.to_string)
}

# Pattern matching in for loops
for (key, val) in pairs {
  out.print("${key}: ${val}")
}

# Range iteration (ranges are built with Int.until/Int.to)
for i in 0.until(10) {
  # i from 0 to 9
}

# Step iteration
for i in 0.until(10).step_by(2) {
  # i is 0, 2, 4, 6, 8
}
```

**Key points:**

- For loops replace methods like `Iter.each`
- Support destructuring patterns directly
- Work with any type implementing `Iter`

### Infinite Loop

```inko
loop {
  # Infinite loop
  if condition {
    break
  }
}
```

### While Loop Pattern

Use `loop` with `break`:

```inko
loop {
  if !condition {
    break
  }
  # Do work
}
```

### Range Syntax

Inko has no `a..b` range literal. Ranges are created with `Int.until` and
`Int.to`:

**Exclusive range** (`until`):

```inko
for i in 0.until(10) {
  # i goes from 0 to 9
}
```

**Inclusive range** (`to`):

```inko
for i in 0.to(10) {
  # i goes from 0 to 10 (inclusive)
}
```

**Ranges as values:**

```inko
let range = 1.to(10)
range.contains?(5)            # => true
range.step_by(2).to_array     # => [1, 3, 5, 7, 9]
range.size                    # => 10
```

### Loop with Index

```inko
let mut i = 0
loop {
  if i >= entries.size {
    break
  }
  match entries.get(i) {
    case Ok(entry) -> {
      # Process entry
    }
    case Error(_) -> {}
  }
  i = i + 1
}
```

**Key points:**

- Inko doesn't have C-style for loops
- Use `loop` with manual index increment
- Remember: No `i++` or `++i`, use `i = i + 1`

---

## Mutability and Borrowing

### Mutable Fields

```inko
type pub Counter {
  let mut @count: Int
}

impl Counter {
  fn pub mut increment {
    @count = @count + 1  # or: @count += 1
  }
}
```

Compound assignment operators (`+=`, `-=`, `*=`, `/=`, `%=`) **are** supported
for integers and any type implementing the matching operator:

```inko
@count += 1        # Same as @count = @count + 1
@total -= amount   # Same as @total = @total - amount
```

Note that `+=` uses the type's `+` operator, so it only works where `+` is
defined (e.g. `Int`, `Float`, `String` — but not `Array`).

### Mutable Parameters

Parameters are immutable (can't be reassigned) unless they're a mutable
reference. Declare mutable references as `param: mut Type`, and pass the value
with `mut` at the call site:

```inko
fn process(input: mut Array[Int]) -> Int {
  input.push(1)
  input.size
}

let mut values = [1, 2]
process(mut values)
```

Mutable borrows of value types (`mut Int`, `mut String`) are a compile error.
To rebind an owned parameter, introduce a new mutable local:

```inko
fn normalize(input: String) -> String {
  let mut out = input.trim
  out = out.to_upper
  out
}
```

### Field Assignments (0.19.1)

Stack-allocated inline/copy types can be assigned through owned references:

```inko
type pub Point {
  let mut @x: Int
  let mut @y: Int

  fn pub mut move_to(x: Int, y: Int) {
    @x = x  # Direct assignment works
    @y = y
  }
}
```

### Assignment vs Swap

**Regular assignment** (`=`):

```inko
let mut x = 10
x = 20  # Reassign
```

**Swap operator** (`:=`):

```inko
let mut a = 10
let mut b = 20
a := b  # Swaps values: a=20, b=10
```

### The `ref` Keyword in Option Types

```inko
fn pub get(key: String) -> Option[ref Object] {
  @entries.iter.find_map(fn (entry) {
    if entry.key == key {
      Option.Some(ref entry.value)  # Return reference, not owned value
    } else {
      Option.None
    }
  })
}
```

**Key points:**

- `Option[ref T]` returns a reference to T
- Use when you want to borrow without transferring ownership
- `ref entry.value` creates a reference to the value
