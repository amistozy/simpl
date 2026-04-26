# simpl

`simpl` is a compact expression language implemented in MoonBit.

This repository serves two purposes:

- a reusable library for parsing and evaluating source code strings
- a small CLI interpreter for running or parsing simpl programs

The language implementation includes:

- recursive-descent parsing
- surface-to-core lowering
- lexical scoping and closures
- pattern matching
- algebraic variants, records, and lists
- mutable references
- UCS-style `if` / `if is` syntax

## Module Metadata

- Module: `amistozy/simpl`
- Canonical README: `README.mbt.md`
- `README.md` is a symbolic link to `README.mbt.md`

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

Run from a file:

```powershell
moon run cmd/main -- path/to/program.simpl
```

Refresh snapshots when needed:

```powershell
moon test --update
```

Before finishing a change:

```powershell
moon info && moon fmt
```

## CLI Usage

The CLI entry point is `cmd/main/main.mbt`.

Supported input modes:

- `--eval` / `-e`: evaluate inline source
- `--file` / `-f`: read source from file
- positional `path`: read source from file (preferred over `--file`)
- `--parse` / `-p`: parse only and print the surface AST

Examples:

```powershell
moon run cmd/main -- -e "let x = 10; x + 1"
moon run cmd/main -- -p -e "if true then 1 else 2"
moon run cmd/main -- examples/basic.simpl
```

## Language Features

- primitives: `Int`, `Bool`, `String`, `nil`
- functions and closures: `fn(x) = ...`
- default params: `fn(x; y = 2; z = 3) = ...`
- required params must appear before defaulted params
- named args in calls: `f(a = 1; 2; c = 3)`
- function sugar where assignment is allowed: `f(x) = ...` (same as `f = fn(x) = ...`)
- default expressions are evaluated when the function is defined
- default expressions cannot reference other parameters
- bindings: `let`, `let ... and ...`, `let rec`, `let rec ... and ...`
- binding update sugar: `+=`, `-=`, `*=`, `/=`, `%=`, `&&=`, `||=`
- control flow: UCS `if`, `if is`
- patterns in `let`, function parameters, and `if is`
- UFCS: `x.foo` -> `foo(x)`, `x.foo(y; z)` -> `foo(x; y; z)` when `foo` is not a record field
- variants such as `#Left(1)` and `#Right("ok")`
- records and lists (using `;` as separator, and `=` in record fields), including list rest patterns
- references: `ref(...)`, dereference `!`, and assignment/update operators

For UCS `if` details, see [IF_SYNTAX.md](IF_SYNTAX.md).

## Public API

Main public functions:

- `parse(String) -> SurfaceExpr raise`
- `eval_source(String) -> Value raise`
- `format_parse_error(ParseError) -> String`
- `parse_error_text(String) -> String?`
- `eval_error_text(String) -> String?`

Test helper functions:

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

Evaluate a source string:

```moonbit nocheck
///|
let value = @simpl.eval_source("1 + 2 * 3")
// => VInt(7)
```

Lexical scoping:

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

References:

```moonbit nocheck
///|
let value = @simpl.eval_source(
  (
    #| let r = ref(1);
    #| do r := 3;
    #| !r + 3
  ),
)
// => VInt(6)
```

## Repository Layout

- `parser.mbt`: lexer, parser, and parse diagnostics
- `simpl.mbt`: AST definitions, lowering, evaluator, runtime helpers
- `simpl_test.mbt`: black-box tests
- `simpl_wbtest.mbt`: white-box tests
- `cmd/main/main.mbt`: CLI entry point
- `IF_SYNTAX.md`: UCS `if` syntax notes

## Development Notes

- Keep MoonBit files block-structured with `///|`.
- Prefer deterministic assertions (`assert_eq`, `assert_true`) for stable behavior.
- Use snapshot tests for broad structured outputs that may evolve.
- Move deprecated blocks into `deprecated.mbt` when applicable.
