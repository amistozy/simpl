# 06. CLI And Embedding

Simpl can be used as a command-line interpreter or as a MoonBit package for
tools and tests.

## Command Line

The CLI entry point is `cmd/main/main.mbt`.

Evaluate inline source:

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

Run a file with the explicit option:

```powershell
moon run cmd/main -- --file program.simpl
```

## Options

```text
simpl [options] [path]
```

- `-e`, `--eval <source>` evaluates an inline source string
- `-f`, `--file <path>` reads source from a file
- `-p`, `--parse` prints the parsed `SurfaceExpr` instead of evaluating

Input rules:

- do not combine `--eval` with file input
- provide a file path only once, either positionally or through `--file`
- with no input, the CLI prints help

## Multi-Block Input

A line containing at least three dashes starts a new block:

```simpl
let x = 1;
x
---
let y = 2;
y
```

Each non-blank block is parsed or evaluated independently. The CLI prints `---`
after each block result. Errors are formatted with the block's original line
offset.

## Output Behavior

Evaluation prints visible results as:

```text
=> value
```

The CLI hides `nil` and lists that contain only `nil` values. This keeps effect
oriented programs such as `say` loops from producing noisy final results.

Use `--parse` when you want to inspect the surface AST:

```powershell
moon run cmd/main -- --parse --eval "=> 1 + 2; it + 3"
```

## Library API

Core entry points:

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

## Embedding Pattern

Use `parse` when a tool needs the surface AST:

```moonbit
let expr = @simpl.parse(source)
```

Use `eval_source` when you only need the final runtime value:

```moonbit
let value = @simpl.eval_source(source)
```

Use `format_error` if you catch raised parse or runtime errors and want a
readable diagnostic:

```moonbit
try @simpl.eval_source(source) catch {
  err => println(@simpl.format_error(err, 0))
}
```

The `*_error_text` helpers are convenient in tests when you want to assert a
diagnostic without manually handling exceptions.

## Development Workflow

Recommended commands:

```powershell
moon test
moon info
moon fmt
```

If intended behavior changes require snapshot updates:

```powershell
moon test --update
```

After changing public APIs, inspect `pkg.generated.mbti` to confirm the visible
interface changed as expected.
