# simpl

`simpl` is a compact interpreter-style language implemented in MoonBit.

The project serves two purposes:

- A small language playground you can run and extend.
- A reusable library for parsing, desugaring, and evaluating expressions in tests or other tools.

It includes a recursive-descent parser, a desugar layer, an evaluator with lexical scoping, and a practical set of language features (patterns, variants, records, lists, references, recursion, and UCS-style conditionals).

## Why This Repo

Use this repository if you want to:

- learn how to build a small language in MoonBit
- study a readable parser + evaluator architecture
- test semantics through source strings or direct AST construction
- experiment with extending syntax and runtime behavior

## Language Snapshot

### Value forms

- `Int`, `Bool`, `String`, `nil`
- lists
- records
- variants
- closures
- references

### Expression forms

- literals and variables
- `let pattern = value in body`
- `let rec f(...) = ... in ...`
- `do expr in body`
- UCS `if`:
  `if | c1 then a | c2 then b else c`
- UCS `if is` pattern split:
  `if value is | p1 then a | p2 then b else c`
- UCS guards (`and`, `and is`) and `or` terminator
- `end` sugar for `else nil`
- function definitions: `fn(...) => expr`
- function calls: `f(x, y)`
- unary ops: `-x`, `not x`
- binary ops: `+ - * / == != < <= > >= && ||`
- references: `ref e`, `!e`, `e1 := e2`
- record/list/variant literals and field access

### Pattern forms

Patterns are used in `let`, function parameters, and UCS `if is`:

- bind: `x`
- wildcard: `_`
- literals: `42`, `true`, `"moon"`, `nil`
- records: `{x, y}`, `{left: #Some(x)}`
- lists: `[x, y]`
- list with rest: `[a, b, ..rest]`
- list with ignored middle: `[head, .., tail]`
- variants: `#Left(x)`
- alternation: `1 | 2`
- guarded patterns: `#Some(x) and x > 0`

## Quick Start

From project root:

```powershell
moon test
moon run cmd/main
```

If snapshots change:

```powershell
moon test --update
```

Before finishing a change:

```powershell
moon info && moon fmt
```

## Minimal Examples

### Evaluate source

```moonbit nocheck
///|
let value = @simpl.eval_source("1 + 2 * 3")
// => VInt(7)
```

### Lexical scoping with closures

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

### Variant pattern split

```moonbit nocheck
///|
let value = @simpl.eval_source(
  (
    #| if #Left(41) is
    #| | #Left(x) then x + 1
    #| | #Right(y) then y
    #| end
  ),
)
// => VInt(42)
```

### References

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

## Library API

The package is `amistozy/simpl`.

Typical pipeline:

1. `parse(source) -> SurfaceExpr`
2. `desugar(surface) -> Expr`
3. `eval(expr) -> Value`

Convenience entry points:

- `eval_source(source)`
- `parse_error_text(source)`
- `eval_error_text(source)`

AST builder helpers (selected):

- literals/vars: `int_lit`, `bool_lit`, `string_lit`, `nil_lit`, `var_ref`
- control flow: `if_then_else`, `let_in`, `let_rec_in`, `let_pattern_in`
- functions: `lambda`, `lambda_patterns`, `call`
- matching: `is_expr`, `match_cases`, `match_case_clauses`
- data: `list`, `record`, `variant`
- refs: `ref_new`, `ref_get`, `ref_set`

Example (AST-first testing style):

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

## Error Reporting

Errors include source ranges, which helps both debugging and stable tests.

Examples:

- parse error: `unexpected token after expression: int at 1:3-4`
- runtime error: `division by zero at 1:1-6`
- pattern failure with location metadata

## Project Layout

- `simpl.mbt`: core AST, desugar, evaluator, helper constructors
- `parser.mbt`: lexer/parser and parse diagnostics
- `simpl_test.mbt`: black-box tests
- `simpl_wbtest.mbt`: white-box tests
- `cmd/main/main.mbt`: runnable sample entry
- `IF_SYNTAX.md`: syntax notes for `if` / UCS-related behavior

## Development Notes

- Keep MoonBit files block-structured (`///|`) and refactor block-by-block when possible.
- Move deprecated code to `deprecated.mbt` when applicable.
- Prefer stable assertions (`assert_eq`, `assert_true`) for deterministic outputs.
- Use snapshots when behavior output is intentionally broad and may evolve.