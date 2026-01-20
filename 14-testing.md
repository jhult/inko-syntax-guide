# Testing

Inko uses the `std.test` module for unit testing. Tests in Inko use a straightforward approach where failures are recorded and tests continue running.

**Official Documentation:** [https://docs.inko-lang.org/manual/latest/guides/tests/](https://docs.inko-lang.org/manual/latest/guides/tests/)

## Directory Structure

Test files follow the naming pattern `test_X.inko` where X represents the tested module name:

```
project/
├── src/
│   └── my_module.inko
└── test/
    └── test_my_module.inko
```

**Note:** Tests and the modules they test exist in the same root namespace, so tests can access private types and methods.

## Writing Tests

```inko
import std.test (Tests)

fn pub tests(t: mut Tests) {
  t.test("String concatenation", fn (t) {
    let result = "Hello" + " " + "World"
    t.equal(result, "Hello World")
  })

  t.test("Array get returns Result", fn (t) {
    let arr = [1, 2, 3]
    match arr.get(0) {
      case Ok(v) -> t.equal(v, 1)
      case Error(_) -> t.true(false)  # Force failure
    }
  })
}
```

**Key points:**

- Use `fn pub tests(t: mut Tests)` as the test entry point
- NOT `type async Main` - tests are synchronous
- No manual `tests.run` - the test framework handles execution
- Use `t.test('description', fn (t) { ... })` for each test case

## Test Assertions

```inko
t.equal(expected, actual)  # Equality check
t.true(value)              # Boolean true assertion
t.false(value)             # Boolean false assertion
```

**Note:** There is no `t.assert()`, `t.pass()`, or `t.fail()` method. Use `t.true(false)` to force a failure if needed.

## Running Tests

Execute tests using the `inko test` command from the project root:

```bash
# Run all tests
inko test

# Filter by test name (runs tests containing "parse")
inko test parse

# Run specific test file
inko test test_parser.inko
```

**Execution behavior:**

- Tests run in randomized order
- Tests run concurrently (default matches available CPU cores)
- If an expectation fails, the failure is recorded and the test continues

## Test Patterns

**Match exhaustive patterns** - Result types require ALL cases:

```inko
match result {
  case Ok(true) -> t.true(true)
  case Ok(false) -> t.true(false)
  case Error(_e) -> t.true(false)
}
```

**Ownership in tests** - Use `.clone()` when values are needed multiple times:

```inko
t.test("Hash multiple times", fn (t) {
  let data = "test".to_byte_array
  let hash1 = hash.hash(data.clone)
  let hash2 = hash.hash(data)  # Original moved here
  t.equal(hash1, hash2)
})
```

## Example Test File

```inko
import std.test (Tests)
import my_module (MyType)

fn pub tests(t: mut Tests) {
  t.test("MyType constructor creates valid instance", fn (t) {
    let instance = MyType.new("test")
    t.equal(instance.name, "test")
  })

  t.test("MyType handles empty input", fn (t) {
    let instance = MyType.new("")
    t.true(instance.empty?)
  })

  t.test("MyType processes data correctly", fn (t) {
    let instance = MyType.new("hello")
    match instance.process {
      case Ok(result) -> t.equal(result, "HELLO")
      case Error(_) -> t.true(false)  # Should not fail
    }
  })
}
```
