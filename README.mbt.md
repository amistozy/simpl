# simpl

`simpl` is a small expression language implemented in MoonBit.

It is both:

- a runnable language playground
- a reusable library for parsing and evaluating source strings

The implementation includes a recursive-descent parser, surface-to-core lowering, lexical scoping, pattern matching, algebraic variants, records, lists, references, and UCS-style `if` syntax.

## Module

- MoonBit module: `amistozy/simpl`
- Canonical README: `README.mbt.md`
- `README.md` is a symbolic link to this file

## Quick Start

Run from project root:

```powershell
moon test
moon run cmd/main
```

When snapshots need refresh:

```powershell
moon test --update
```

Before finishing a change:

```powershell
moon info && moon fmt
```

## Language Highlights

- primitives: `Int`, `Bool`, `String`, `nil`
- functions and closures: `fn(x) => ...`, function calls
- bindings: `let ...; ...`, recursive `let rec`
- control flow: UCS `if` and `if is`
- pattern matching in `let`, parameters, and `if is`
- algebraic variants (for example `#Left(1)`)
- records and lists (including list rest patterns)
- mutable references: `ref`, `!`, `:=`
- arithmetic, comparison, and boolean operators

See [`IF_SYNTAX.md`](IF_SYNTAX.md) for detailed UCS `if` notes.

## Public API

Public entry points are intentionally compact:

- `parse(source : String) -> SurfaceExpr raise`
- `eval_source(source : String) -> Value raise`
- `format_parse_error(error : ParseError) -> String`
- `parse_error_text(source : String) -> String?`
- `eval_error_text(source : String) -> String?`
- test helpers:
  - `parse_is_ok`, `parse_is_error`
  - `eval_source_is_int`, `eval_source_is_string`, `eval_source_is_bool`, `eval_source_is_error`

Public types:

- `SurfaceExpr`
- `Expr`
- `Value`
- `ParseError`

## Examples

Evaluate source:

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

Pattern split with UCS `if is`:

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
    #| let r = ref 1;
    #| do r := 3;
    #| !r + 3
  ),
)
// => VInt(6)
```

## Repository Layout

- `parser.mbt`: lexer/parser and parse diagnostics
- `simpl.mbt`: core AST, lowering, evaluator, runtime helpers
- `simpl_test.mbt`: black-box tests
- `simpl_wbtest.mbt`: white-box tests
- `cmd/main/main.mbt`: runnable entry point
- `IF_SYNTAX.md`: UCS `if` design notes

## Development Notes

- Keep MoonBit files block-structured with `///|`.
- Prefer deterministic assertions (`assert_eq`, `assert_true`) for stable behavior.
- Use snapshot tests when broad structured output is expected to evolve.
- Put deprecated blocks in `deprecated.mbt` when needed.
