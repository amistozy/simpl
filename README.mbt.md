# simpl

`simpl` is a compact expression language implemented in MoonBit.

This repository provides both:

- a reusable library for parsing and evaluating Simpl programs
- a CLI interpreter for running `.simpl` files or inline source

Module: `amistozy/simpl`

## Highlights

- Expression-oriented syntax with first-class functions
- Pattern matching in `let`, function parameters, and `if ... is`
- Structured conditional splitting with `if / and / is / or / else / end`
- Records, variants, lists, references, and UFCS-style fallback calls
- Parse and runtime errors with source positions

## Requirements

- [MoonBit](https://docs.moonbitlang.com)

## Quick Start

Run tests:

```powershell
moon test
```

Evaluate inline code:

```powershell
moon run cmd/main -- --eval "1 + 2 * 3"
```

Parse only:

```powershell
moon run cmd/main -- --parse --eval "let x = 1; x"
```

Run a source file:

```powershell
moon run cmd/main -- path/to/program.simpl
```

## CLI Usage

Entry point: `cmd/main/main.mbt`

```text
simpl [options] [path]
```

Options:

- `-e, --eval <source>`: evaluate inline source code
- `-f, --file <path>`: evaluate source from file
- `-p, --parse`: parse only and print `SurfaceExpr`
- positional `path`: source file path (recommended for file input)

Input rules:

- Do not combine `--eval` with file input
- Do not provide file input twice (`--file` + positional path)
- If no input is provided, help text is shown

### Multi-block input in CLI

The CLI supports splitting one source into multiple blocks by lines made of at least three dashes (for example `---`).
Each block is parsed/evaluated independently, and errors are reported with adjusted line offsets.

## Language Overview

### Literals and Values

- Integers: `1`, `42`
- Booleans: `true`, `false`
- Strings: `"hello"`
- Nil: `nil`
- Lists: `[1; 2; 3]`
- Records: `{x = 1; y = 2}`
- Variants: `#Some(1)`, `#Left("err")`

### Operators

- Arithmetic: `+ - * / %`
- Comparison: `== != < <= > >=`
- Boolean: `&& ||` (short-circuit, returns operand values)
- Unary:
  - `-x` numeric negate
  - `!x` boolean-not; if `x` is a ref, dereference
  - `$x` convert value to string

Runtime details:

- `a / 0` returns `0`
- `a % 0` returns `a`

### Bindings and Functions

- `let` bindings and sequencing with `;`
- grouped bindings with `let ... and ...`
- recursive and mutually recursive functions via `let rec` / `let rec ... and ...`
- lambdas: `fn(x) = x + 1`, `fn x = x + 1`
- function-definition sugar: `f(x) = ...`, `f x = ...`
- default parameters are supported (required parameters must come first)
- positional and named call arguments are both supported

### Pattern Matching

Patterns are available in bindings, parameters, and `if ... is` arms.

Supported pattern forms:

- variable binders and wildcard `_`
- literal patterns (`1`, `true`, `"ok"`, `nil`)
- variant patterns (`#Some(x)`)
- list patterns and rest patterns (`[head; ..tail]`)
- record patterns
- pattern alternatives with `|`

### Condition Split Syntax

Simpl supports structured branch splitting with `if`, `and`, `is`, `or`, `else`, and `end`.

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

See detailed syntax notes in [docs/syntax/IF_SYNTAX.md](docs/syntax/IF_SYNTAX.md) and [docs/syntax/README.md](docs/syntax/README.md).

### References and Updates

- Create: `ref(expr)`
- Dereference: `!r`
- Assign: `r := value`
- Update in place: `+= -= *= /= %= &&= ||=`

### List Calls

- `list(n)`: index into list by `n`
- negative indices are supported (`-1` means last element)
- out-of-range indices return `nil`
- `list(xs)` where `xs` is `List[Int]`: batch indexing, equivalent to mapping each index over `list`

### UFCS-style Fallback

- `x.foo` can fall back to `foo(x)`
- `x.foo(y; z)` can fall back to `foo(x; y; z)`
- Real record fields take priority over fallback

### String Calls

Simpl uses expression-based string composition:

- if `a` is `String`, `a(str)` performs concatenation
- if `a` is `String`, `a(list)` joins list items with `a` as separator

```simpl
let name = "Alice";
let age = 18;
name" is "$age" years old"
```

## Built-in Functions

Current built-ins:

- `ref(value)`
- `say(value)`
- `map(list; f)`
- `length(list_or_string)`
- `max(list_of_int)`
- `min(list_of_int)`
- `sum(list_of_int)`

Note: built-ins do not accept named arguments.

## Public Library API

Primary functions:

- `parse(String) -> SurfaceExpr raise`
- `eval_source(String) -> Value raise`
- `format_parse_error(ParseError) -> String`
- `parse_error_text(String) -> String?`
- `eval_error_text(String) -> String?`

Common testing helpers:

- `parse_is_ok(String) -> Bool`
- `parse_is_error(String) -> Bool`
- `eval_source_is_int(String, Int) -> Bool`
- `eval_source_is_string(String, String) -> Bool`
- `eval_source_is_bool(String, Bool) -> Bool`
- `eval_source_is_error(String) -> Bool`

Key exposed types:

- `SurfaceExpr`
- `Value`

## Repository Layout

- `simpl.mbt`: AST, desugaring, evaluator, runtime model
- `parser.mbt`: lexer/parser integration and parse diagnostics
- `lexer.mbt`: lexical analysis
- `desugar.mbt`: surface-to-core transformation
- `pattern.mbt`: pattern utilities
- `apply.mbt`: function/application-related logic
- `pretty.mbt`: pretty-printing support
- `simpl_test.mbt`: black-box tests
- `simpl_wbtest.mbt`: white-box tests
- `cmd/main/main.mbt`: CLI implementation
- `docs/syntax/`: focused syntax references
- `editors/vscode-simpl/`: VS Code syntax-highlighting extension

## Development Workflow

Recommended loop:

```powershell
moon test
moon info
moon fmt
```

If snapshot output intentionally changes:

```powershell
moon test --update
```

Tips:

- Keep MoonBit files in block style (`///|`)
- Prefer stable assertion tests (`assert_eq`, `assert_true`) where possible
- Check `.mbti` diffs after `moon info` to confirm intended public API changes

## License

Apache-2.0. See [LICENSE](LICENSE).
