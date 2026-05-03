# Simpl

Simpl is a small dynamic expression language implemented in MoonBit.

It is meant to be compact, readable, and easy to embed. The language has a few
deliberately strong ideas:

- every program is an expression
- patterns work in bindings, function parameters, and conditional branches
- many values are callable, not only functions
- the syntax favors small composable forms over a large statement set

Module: `amistozy/simpl`

## Quick Taste

```simpl
let greet(name; title = "friend") =
  "Hello, "title" "name"!";

greet "Ada"
```

```simpl
let score_label(result) =
  if result is
  | #Ok(score) and score >= 60 then "pass: "$score
  | #Ok(score) then "retry: "$score
  | #Err(message) then message
  else "unknown";

score_label #Ok(72)
```

```simpl
let rec qsort(xs) =
  guard xs is [x; ..rest] else [];
  let smaller = qsort rest.filter fn _ <= x;
  let larger = qsort rest.filter fn _ > x;
  smaller + [x] + larger;

qsort [4; 1; 5; 1; 3]
```

```simpl
[1; 20; 3]
.map(fn: (_ + 1) * 2)
.filter(fn _ < 10)
```

## Features

- Dynamic values: integers, booleans, strings, `nil`, lists, records, variants,
  references, closures, and built-ins.
- Expression forms: `let`, `let and`, `let rec`, `do`, `guard`, `if`, `with`,
  lambdas, calls, field access, and `=>` probes.
- Pattern forms: binders, `_`, literals, variants, records, lists, list rests,
  alternatives, and `as` patterns.
- Call forms: positional and named arguments, default parameters, trailing
  application, `fn expr` eta-expansion, and UFCS-style field fallback.
- Callable data: strings concatenate or join, integers repeat, lists index or
  collect, and records produce updated copies from named arguments.
- Built-ins for references, printing, list transforms, length, reverse, min,
  max, and sum.
- Diagnostics: parse and runtime errors include source positions.

## Requirements

Install [MoonBit](https://docs.moonbitlang.com).

## Run Simpl

Run the test suite:

```powershell
moon test
```

Evaluate inline source:

```powershell
moon run cmd/main -- --eval "1 + 2 * 3"
```

Parse without evaluating:

```powershell
moon run cmd/main -- --parse --eval "let x = 1; x"
```

Run a file:

```powershell
moon run cmd/main -- program.simpl
```

The CLI accepts multi-block input. A line containing at least three dashes, such
as `---`, splits the file into independent parse or evaluation blocks.

## Library API

Public entry points:

- `parse(String) -> SurfaceExpr raise`
- `eval_source(String) -> Value raise`
- `format_error(Error, Int) -> String`
- `parse_error_text(String) -> String?`
- `eval_error_text(String) -> String?`

Test helpers:

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

Read the language guide in this order:

1. [01 - Language Tour](docs/01-language-tour.md)
2. [02 - Functions and Calls](docs/02-functions-and-calls.md)
3. [03 - Control Flow and Patterns](docs/03-control-flow-and-patterns.md)
4. [04 - Data and Mutation](docs/04-data-and-mutation.md)
5. [05 - Callable Composition](docs/05-composition-patterns.md)
6. [06 - CLI and Embedding](docs/06-cli-and-embedding.md)

## Repository Layout

- `simpl.mbt`: AST definitions, runtime values, evaluator, and public helpers
- `lexer.mbt`: tokenization and source spans
- `parser.mbt`: surface parser and diagnostics
- `desugar.mbt`: surface-to-core lowering
- `pattern.mbt`: pattern matching, truthiness, and value summaries
- `apply.mbt`: call semantics and built-ins
- `pretty.mbt`: pretty-printers for ASTs and values
- `cmd/main/main.mbt`: command-line interpreter
- `simpl_test.mbt`: black-box tests
- `simpl_wbtest.mbt`: white-box tests

## Development

Recommended validation loop:

```powershell
moon test
moon info
moon fmt
```

If an intentional behavior change affects snapshots, refresh them with:

```powershell
moon test --update
```

## License

Apache-2.0. See `LICENSE`.
