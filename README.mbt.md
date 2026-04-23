# simpl

`simpl` is a small interpreter-style language implemented in MoonBit. It also exposes a reusable parser and evaluator API, so the project works both as a language playground and as a compact reference implementation for building small languages in MoonBit.

This repository is a good fit if you want to:

- learn how a small language can be implemented in MoonBit
- study a recursive-descent parser and evaluator in a compact codebase
- write tests directly against an AST instead of only using source strings
- extend the language into a larger experimental interpreter

The current implementation already covers a strong set of core features for language experiments, including expression evaluation, lexical scoping, closures, recursion, pattern matching, records, variants, lists, and references.

## Highlights

- Separate parser and evaluator layers
- Lexical scoping and closures
- Recursive functions via `let rec`
- Shared pattern syntax for `match`, `let`, and function parameters
- Dynamic values including records, lists, variants, and references
- Error messages with source locations
- Both source-based and AST-based entry points

## Language Features

### Values

- `Int`
- `Bool`
- `String`
- `nil`
- lists
- records
- variants
- closures
- references

### Expressions

- literals and variables
- `let pattern = value in body`
- `let rec f(...) = ... in ...`
- `do expr in body`
- `if cond then a else b`
- `fn(...) => expr`
- `match expr with | ...` with optional `end` for nested matches
- `expr is pattern`
- function calls such as `f(x, y)`
- unary operators: `-x`, `not x`
- binary operators: `+ - * / == != < <= > >= and or && ||`
- reference operations: `ref e`, `!e`, `e1 := e2`
- record literals and field access, such as `{x: 1}` and `p.x`
- list literals such as `[1, 2, 3]`
- variant literals such as `#Left(1)`

### Patterns

Patterns are used not only in `match`, but also in `let` bindings and function parameters.

Supported pattern forms include:

- variable bindings such as `x`
- wildcard `_`
- literal patterns such as `42`, `true`, `"moon"`, and `nil`
- record patterns such as `{x, y}` and `{left: #Some(x)}`
- list patterns such as `[x, y]`
- list patterns with a rest binding such as `[a, b, ..rest]`
- list patterns with an ignored middle slice such as `[head, .., tail]`
- variant patterns such as `#Left(x)`
- or-patterns such as `1 | 2`
- guards such as `#Some(x) if x > 0 -> ...`

## Quick Examples

### Evaluate Source Directly

```moonbit nocheck
///|
let value = @simpl.eval_source("1 + 2 * 3")
// => VInt(7)
```

### Closures and Lexical Scoping

```moonbit nocheck
///|
let value = @simpl.eval_source(
  (
    #| let x = 10 in
    #| let f(y) = x + y in
    #| let x = 100 in
    #| f(5)
  ),
)
// => VInt(15)
```

### Record Destructuring

```moonbit nocheck
///|
let value = @simpl.eval_source(
  (
    #| let p = {x: 10, y: 32} in
    #| let {x, y} = p in
    #| x + y
  ),
)
// => VInt(42)
```

### Variants and Pattern Matching

```moonbit nocheck
///|
let value = @simpl.eval_source(
  (
    #| match #Left(41) with
    #| | #Left(x) -> x + 1
    #| | #Right(y) -> y
  ),
)
// => VInt(42)
```

### Pattern Tests

```moonbit nocheck
///|
let value = @simpl.eval_source(
  (
    #| if [#Left(1), #Right(2)] is [#Left(x), #Right(y)] then
    #|   x + y
    #| else
    #|   0
  ),
)
// => VInt(3)
```

Bindings introduced by `is` flow through left-to-right `and`/`or` expressions
and into the true branch of `if`. In a successful `match` guard, they also flow
into that case body.

### References and Assignment

```moonbit nocheck
///|
let value = @simpl.eval_source(
  (
    #| let r = ref 1 in
    #| do r := 3 in
    #| !r + 3
  ),
)
// => VInt(6)
```

## Using It as a Library

The project supports both source-string execution and manual AST construction.

### Run from Source Strings

```moonbit nocheck
///|
let result = @simpl.eval_source(
  "let rec fact(n) = if n == 0 then 1 else n * fact(n - 1) in fact(5)",
)
```

Common entry points:

- `parse(source)` parses source into an `Expr`
- `eval(expr)` evaluates an AST
- `eval_source(source)` parses and evaluates source
- `parse_error_text(source)` returns formatted parse error text
- `eval_error_text(source)` returns formatted runtime error text

### Construct ASTs Manually

```moonbit nocheck
///|
let expr = @simpl.add(
  @simpl.int_lit(1),
  @simpl.mul(@simpl.int_lit(2), @simpl.int_lit(3)),
)

///|
let value = @simpl.eval(expr)
// => VInt(7)
```

Useful constructors include:

- literals and variables: `int_lit`, `bool_lit`, `string_lit`, `nil_lit`, `var_ref`
- control flow: `if_then_else`, `let_in`, `let_rec_in`
- pattern tests: `is_expr`
- functions: `lambda`, `call`
- composite values: `list`, `record`, `variant`
- pattern-related helpers: `let_pattern_in`, `lambda_patterns`, `match_cases`
- references: `ref_new`, `ref_get`, `ref_set`

If you are writing tests, AST construction is often more stable than asserting against source strings.

## Error Reporting

`simpl` reports errors with source locations, which makes debugging and testing much easier. Examples:

- parse error: `unexpected token after expression: int at 1:3-4`
- runtime error: `division by zero at 1:1-6`
- pattern failure: `pattern match failure: expected [x, y], got [1] at 1:5-22`

This makes the project useful both for interactive experiments and for precise test assertions.

## Project Layout

- [`simpl.mbt`](simpl.mbt): interpreter core, runtime values, and AST helper constructors
- [`parser.mbt`](parser.mbt): lexer, parser, and error formatting
- [`simpl_test.mbt`](simpl_test.mbt): black-box tests covering language features and error behavior
- [`simpl_wbtest.mbt`](simpl_wbtest.mbt): white-box tests
- [`cmd/main/main.mbt`](cmd/main/main.mbt): a minimal runnable entry point

## Development

Run these commands from the project root:

```powershell
moon test
```

```powershell
moon run cmd/main
```

```powershell
moon info
moon fmt
```

If your changes affect snapshot outputs, update them with:

```powershell
moon test --update
```

## Good Next Extensions

- a richer standard library
- more pattern forms and data structures
- `while`, a module system, or additional control-flow forms
- a friendlier REPL
- more advanced error recovery and diagnostics

If you want to study how to implement a small language in MoonBit, this repository is already a solid starting point: the structure is approachable, the tests are clear, and the semantic boundaries are fairly explicit.
