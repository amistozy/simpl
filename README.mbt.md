# simpl

`simpl` is a compact expression language implemented in MoonBit.

This repository provides:

- A reusable library for parsing and evaluating Simpl source code
- A small CLI interpreter for running and inspecting Simpl programs

Module: `amistozy/simpl`

## Goals

- Keep syntax compact and expression-oriented
- Support composable condition splits (`if / is / and / or`)
- Preserve a clear surface-to-core desugaring pipeline
- Provide source-positioned parse diagnostics

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

Before finalizing changes:

```powershell
moon info && moon fmt
```

## CLI Usage

Entry: `cmd/main/main.mbt`

- `-e, --eval <source>`: evaluate inline source
- `-f, --file <path>`: read source from file
- positional `path`: read source from file (preferred)
- `-p, --parse`: parse only and print `SurfaceExpr`

Rules:

- Do not combine `--eval` with file input
- Do not pass file input twice (`--file` + positional path)
- No input prints help

Examples:

```powershell
moon run cmd/main -- -e "let x = 10; x + 1"
moon run cmd/main -- -p -e "if true then 1 else 2"
moon run cmd/main -- examples/basic.simpl
```

## Language Overview

### Values and Operators

- Literals: `Int`, `Bool`, `String`, `nil`
- Arithmetic: `+ - * / %`
- Comparison: `== != < <= > >=`
- Boolean: `&& ||` (short-circuit, returns operand values)
- Unary: `-` (negate), `!` (not/deref), `$` (to string)

Runtime notes:

- Division by zero returns `0`
- Modulo by zero returns the dividend

### Bindings, Functions, and Calls

- `let ...; body` and `do ...; body`
- `let ... and ...` grouped bindings
- `let rec` and `let rec ... and ...` (mutual recursion)
- Lambdas: `fn(params) = body` and `fn x = body`
- Function sugar: `f(x) = ...` and `f x = ...`
- Default parameters (required params must come first)
- Named and positional args (named bound first)
- Trailing call sugar: `f x`, `f(1; 2) 3`
- `with` sugar: `with(params) = call(...); body`

### Pattern Matching

Supported in `let`, function params, and `if ... is` branches:

- Variable binders and `_`
- Literal patterns
- Variant patterns (for example `#Some(x)`)
- List patterns and rest patterns (`[head; ..rest]`)
- Record patterns and shorthand fields
- Pattern alternatives with `|`

### Data Structures

- Variants: `#Left(1)`, `#Right("ok")`
- Records: `{x = 1; y = 2}`, shorthand `{x; y = 2}`
- Lists: `[1; 2; 3]`

### References and Updates

- Create: `ref(expr)`
- Dereference: `!r`
- Assign: `r := value`
- Update: `+= -= *= /= %= &&= ||=`

Note: `let x += y` is rebinding sugar, equivalent to `let x = x + y`.

### UFCS Fallback

- `x.foo` may resolve to `foo(x)`
- `x.foo(y; z)` may resolve to `foo(x; y; z)`
- Record field lookup has priority over UFCS fallback

### String Calls and Interpolation

Simpl has no dedicated template string syntax. Interpolation is expression-based:

- If `a` is `String`, `a(str)` means concatenation
- If `a` is `String`, `a(list)` joins list items with `a` as separator
- `$expr` converts a value to string (`$"text"` returns `"text"` without extra quotes)

Example:

```simpl
let name = "Alice";
let age = 18;
name" is "$age" years old"
```

### Builtins

- `ref(value)`: reference cell
- `say(value)`: prints a value and returns `nil` (strings are printed as raw text)
- `map(list; f)`: maps a function over a list

Builtins do not accept named arguments.

## Conditional Syntax (UCS Subset)

Simpl supports split points `if`, `is`, and `and`.  
`or` closes the current split; `else` and `end` close with fallback behavior.

Examples:

```simpl
if
| n < 0 then "neg"
| n == 0 then "zero"
else "pos"
```

```simpl
if value is
| #Left(x) then x
| #Right(y) then y
else 0
```

```simpl
if ready and
  | has_cache then "cache"
  | has_network then "network"
  or
else "idle"
```

See full details in `docs/syntax/IF_SYNTAX.md`.

## Public API

Primary functions:

- `parse(String) -> SurfaceExpr raise`
- `eval_source(String) -> Value raise`
- `format_parse_error(ParseError) -> String`
- `parse_error_text(String) -> String?`
- `eval_error_text(String) -> String?`

Test helpers:

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

Evaluate source:

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

- `parser.mbt`: lexer, parser, parse diagnostics, parse/eval wrappers
- `simpl.mbt`: AST, desugaring, evaluator, runtime semantics
- `simpl_test.mbt`: blackbox tests
- `simpl_wbtest.mbt`: whitebox tests
- `cmd/main/main.mbt`: CLI implementation
- `docs/syntax/*.md`: focused syntax notes
- `editors/vscode-simpl`: VS Code syntax highlighting extension

## Development Notes

- Keep MoonBit files block-structured with `///|`
- Prefer stable assertions (`assert_eq`, `assert_true`)
- Update snapshots only for intentional output changes
- Move deprecated blocks to `deprecated.mbt` when needed
