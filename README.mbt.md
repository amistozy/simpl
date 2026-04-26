# simpl

`simpl` is a compact expression language implemented in MoonBit.

This repository provides:

- a reusable library for parsing and evaluating Simpl source strings
- a small CLI interpreter for running or inspecting Simpl programs

## What Simpl Includes

- recursive-descent parser with source-span diagnostics
- surface-to-core desugaring pipeline
- lexical scoping and closures
- pattern matching in `let`, `fn` parameters, and `if is`
- records, variants, and lists
- references and update operators
- UCS-style conditional syntax (`if`, `is`, `and`, `or`, `else`, `end`)
- UFCS fallback (`x.foo` / `x.foo(...)`)

## Module Metadata

- Module: `amistozy/simpl`
- Readme entry in `moon.mod.json`: `README.mbt.md`
- `README.md` is a symlink to this file

## Quick Start

From the repository root:

```powershell
moon test
moon run cmd/main -- --eval "1 + 2 * 3"
```

Parse only:

```powershell
moon run cmd/main -- --parse --eval "let x = 1; x"
```

Run a file:

```powershell
moon run cmd/main -- path/to/program.simpl
```

Update snapshots when behavior intentionally changes:

```powershell
moon test --update
```

Before finalizing a change:

```powershell
moon info && moon fmt
```

## CLI Usage

Entry point: `cmd/main/main.mbt`

Input modes:

- `--eval` / `-e`: evaluate inline source
- `--file` / `-f`: read source from file
- positional `path`: read source from file (preferred)
- `--parse` / `-p`: parse only and print `SurfaceExpr`

Rules enforced by CLI:

- do not combine `--eval` with file input
- do not provide file path twice (`--file` + positional)
- no input prints help text

Examples:

```powershell
moon run cmd/main -- -e "let x = 10; x + 1"
moon run cmd/main -- -p -e "if true then 1 else 2"
moon run cmd/main -- examples/basic.simpl
```

## Language Tour

### Values and Operators

- literals: `Int`, `Bool`, `String`, `nil`
- arithmetic: `+ - * / %`
- comparison: `== != < <= > >=`
- boolean operators: `&& ||` (short-circuit, return operand values)

### Bindings and Functions

- `let` bindings and `do` sequencing
- `let ... and ...` parallel-style bindings
- `let rec` and `let rec ... and ...` for recursion and mutual recursion
- lambdas: `fn(params) = body`
- named function sugar: `f(x) = ...` where assignment sugar is allowed
- default parameters with required-before-default ordering
- named arguments in calls
- trailing call sugar (`f x`, `f(a) b`)

### Patterns

Supported in `let`, function params, and `if is` arms:

- binders, literals, `_`
- variants, lists, list-rest patterns
- record patterns and field shorthand
- pattern alternatives with `|`

### Data Structures

- variants: `#Left(1)`, `#Right("ok")`
- records: `{x = 1; y = 2}`, shorthand `{x; y = 2}`
- lists: `[1; 2; 3]`

### References and Mutation

- create: `ref(expr)`
- dereference: `!r`
- assign: `r := value`
- update sugar: `+= -= *= /= %= &&= ||=`

### UFCS Fallback

- `x.foo` can resolve to `foo(x)`
- `x.foo(y; z)` can resolve to `foo(x; y; z)`
- record field lookup takes priority over UFCS fallback

### Builtins

- `ref(value)` -> reference cell
- `print(value)` -> prints value, returns `nil`
- `say(string)` -> prints string text, returns `nil`

Builtins do not accept named arguments.

## Public API

Primary public functions:

- `parse(String) -> SurfaceExpr raise`
- `eval_source(String) -> Value raise`
- `format_parse_error(ParseError) -> String`
- `parse_error_text(String) -> String?`
- `eval_error_text(String) -> String?`

Testing helpers:

- `parse_is_ok(String) -> Bool`
- `parse_is_error(String) -> Bool`
- `eval_source_is_int(String, Int) -> Bool`
- `eval_source_is_string(String, String) -> Bool`
- `eval_source_is_bool(String, Bool) -> Bool`
- `eval_source_is_error(String) -> Bool`

Public types:

- `SurfaceExpr`
- `Expr`
- `Value`
- `ParseError`

## Library Examples

Evaluate source text:

```moonbit nocheck
///|
let value = @simpl.eval_source("1 + 2 * 3")
// => VInt(7)
```

Lexical closure capture:

```moonbit nocheck
///|
let value = @simpl.eval_source(
  (
    #| let x = 10;
    #| let f(y) = x + y;
    #| let x = 100;
    #| f(5)
  ),
)
// => VInt(15)
```

Pattern split with `if is`:

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

## Repository Layout

- `parser.mbt`: lexer, parser, parse diagnostics, parse/eval entry wrappers
- `simpl.mbt`: ASTs, desugaring, evaluator, runtime behavior
- `simpl_test.mbt`: black-box tests
- `simpl_wbtest.mbt`: white-box tests
- `cmd/main/main.mbt`: CLI implementation
- `IF_SYNTAX.md`: detailed UCS `if` syntax notes
- `FUNCTION_SYNTAX.md`: detailed function syntax notes

## Development Notes

- Keep MoonBit files block-structured with `///|`.
- Prefer deterministic assertions (`assert_eq`, `assert_true`) for stable behavior.
- Use snapshot updates only when output changes are intentional.
- Move deprecated blocks into `deprecated.mbt` when applicable.
