# simpl

`simpl` is a small expression language implemented in MoonBit.

It can be used in two ways:

- as a MoonBit package for parsing and evaluating Simpl source
- as a command-line interpreter for `.simpl` files or inline snippets

Module: `amistozy/simpl`

## Why Simpl exists

Simpl explores a compact language design built around a few ideas:

- everything is an expression
- patterns are reused across bindings, parameters, and conditional refinement
- calls are a general composition mechanism, not just function invocation
- concise syntax is preferred when it still stays readable

The result is a language that feels small, but still supports structured data,
closures, mutation through references, and a surprisingly rich call model.

## A quick taste

```simpl
let greet(name; title = "friend") =
  "Hello, "title" "name"!";

greet("Ada")
```

```simpl
let describe(value) =
  if value is
  | #Ok(x) and x > 0 then "positive"
  | #Ok(0) then "zero"
  | #Err(msg) then msg
  else "unknown";

describe(#Ok(3))
```

```simpl
[1; 20; 3]
.map(fn: (_ + 1) * 2)
.filter(fn _ < 10)
```

## Feature snapshot

- integers, booleans, strings, `nil`, lists, records, variants, references, and functions
- lexical closures and first-class functions
- `let`, `let and`, `let rec`, and `let rec ... and ...`
- destructuring patterns in `let`, parameters, and `if ... is`
- named arguments and call-time default parameters
- trailing application such as `f x` and `f(1; 2) 3`
- `fn expr` eta-expansion with underscore placeholders
- `with` sugar for passing a trailing lambda
- record field access with UFCS-style fallback
- expression-based string interpolation using string calls and `$`
- source-positioned parse and runtime errors

## Install requirements

- [MoonBit](https://docs.moonbitlang.com)

## Quick start

Run the test suite:

```powershell
moon test
```

Evaluate inline code:

```powershell
moon run cmd/main -- --eval "1 + 2 * 3"
```

Parse without evaluation:

```powershell
moon run cmd/main -- --parse --eval "let x = 1; x"
```

Run a file:

```powershell
moon run cmd/main -- program.simpl
```

## CLI

The interpreter entry point is `cmd/main/main.mbt`.

```text
simpl [options] [path]
```

Options:

- `-e`, `--eval <source>`: evaluate an inline source string
- `-f`, `--file <path>`: read source from a file
- `-p`, `--parse`: parse only and print the surface AST

Input rules:

- do not combine `--eval` with file input
- provide a file path only once, either positionally or through `--file`
- when no input is provided, the CLI prints help

The CLI also supports multi-block input. A line made of at least three dashes,
such as `---`, splits the source into separate blocks. Each block is parsed or
evaluated independently.

## Library API

Public entry points:

- `parse(String) -> SurfaceExpr raise`
- `eval_source(String) -> Value raise`
- `format_error(Error, Int) -> String`
- `parse_error_text(String) -> String?`
- `eval_error_text(String) -> String?`

Useful test helpers:

- `parse_is_ok`
- `parse_is_error`
- `eval_source_is_int`
- `eval_source_is_string`
- `eval_source_is_bool`
- `eval_source_is_error`

Public types:

- `SurfaceExpr`
- `Value`

## Documentation

Read the docs in this order:

1. [01 - Language Tour](docs/01-language-tour.md)
2. [02 - Functions and Calls](docs/02-functions-and-calls.md)
3. [03 - Control Flow and Patterns](docs/03-control-flow-and-patterns.md)
4. [04 - Data and Mutation](docs/04-data-and-mutation.md)
5. [05 - Composition Patterns](docs/05-composition-patterns.md)
6. [06 - CLI and Embedding](docs/06-cli-and-embedding.md)

## Repository layout

- `simpl.mbt`: core AST, runtime values, evaluator
- `parser.mbt`: parser and diagnostics
- `lexer.mbt`: lexer and source spans
- `desugar.mbt`: surface-to-core lowering
- `pattern.mbt`: pattern logic and truthiness helpers
- `apply.mbt`: call semantics and built-ins
- `pretty.mbt`: pretty-printing
- `cmd/main/main.mbt`: CLI
- `simpl_test.mbt`: black-box tests
- `simpl_wbtest.mbt`: white-box tests

## Development notes

Recommended validation loop:

```powershell
moon test
moon info
moon fmt
```

If you intentionally change behavior that affects snapshots:

```powershell
moon test --update
```

## License

Apache-2.0. See `LICENSE`.
