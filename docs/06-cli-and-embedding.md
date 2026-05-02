# 06. CLI and Embedding

This page covers how to run Simpl from the command line and how to use the
MoonBit package from another module.

## Running the CLI

The interpreter entry point lives in `cmd/main/main.mbt`.

Run inline source:

```powershell
moon run cmd/main -- --eval "1 + 2 * 3"
```

Parse only:

```powershell
moon run cmd/main -- --parse --eval "let x = 1; x"
```

Run a file:

```powershell
moon run cmd/main -- program.simpl
```

Or explicitly use `--file`:

```powershell
moon run cmd/main -- --file program.simpl
```

## CLI options

- `-e`, `--eval <source>`: evaluate inline source
- `-f`, `--file <path>`: read source from a file
- `-p`, `--parse`: print the parsed surface AST instead of evaluating

Rules:

- `--eval` cannot be combined with file input
- `--file` and positional file input cannot be combined
- no input means help text is shown

## Multi-block input

The CLI understands block separators. A line containing at least three dashes
starts a new block:

```simpl
let x = 1;
x
---
let y = 2;
y
```

Each block is parsed or evaluated independently, and errors are reported with
their block-aware line offsets.

## Using the library

The public API is intentionally small.

Core entry points:

- `parse(String) -> SurfaceExpr raise`
- `eval_source(String) -> Value raise`
- `format_error(Error, Int) -> String`
- `parse_error_text(String) -> String?`
- `eval_error_text(String) -> String?`

Convenience helpers:

- `parse_is_ok`
- `parse_is_error`
- `eval_source_is_int`
- `eval_source_is_string`
- `eval_source_is_bool`
- `eval_source_is_error`

Public types:

- `SurfaceExpr`
- `Value`

## Typical embedding flow

For tools, tests, or experiments, the common flow is:

1. call `parse` when you need a surface AST
2. call `eval_source` when you want a runtime value directly
3. use `format_error` when you need readable diagnostics

The convenience helpers are especially useful in tests because they keep common
assertions short.

## Development workflow

Recommended commands while working on the language:

```powershell
moon test
moon info
moon fmt
```

If you intentionally change snapshot output:

```powershell
moon test --update
```
