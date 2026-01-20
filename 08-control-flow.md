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

# Range iteration
for i in 0..10 {
  # i from 0 to 9
}

# Step iteration
for i in 0..10 {
  if i % 2 == 0 {
    # Process even numbers
  }
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
  if not condition {
    break
  }
  # Do work
}
```

### Range Syntax

**Exclusive range** (`..`):

```inko
for i in 0..10 {
  # i goes from 0 to 9
}
```

**Inclusive range** (`..=`):

```inko
for i in 0..=10 {
  # i goes from 0 to 10 (inclusive)
}
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
    @count = @count + 1  # NOT += (operator doesn't exist)
  }
}
```

**CRITICAL:** Inko does NOT have `+=`, `-=`, `*=`, `/=` operators. Always write out the full assignment:

- `@count += 1`
- `@count = @count + 1`

### Mutable Parameters

```inko
fn pub process(mut input: String) -> String {
  input = input.to_upper
  input
}
```

### Field Assignments (0.19.1)

Stack-allocated inline/copy types can be assigned through owned references:

```inko
type pub Point {
  let mut @x: Int
  let mut @y: Int
}

fn pub mut move_to(x: Int, y: Int) {
  @x = x  # Direct assignment works
  @y = y
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
