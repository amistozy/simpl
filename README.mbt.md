# simpl

`simpl` is a small expression language implemented in MoonBit.

It is both:

- a reusable MoonBit package for parsing and evaluating Simpl source
- a command-line interpreter for `.simpl` programs and inline snippets

Module: `amistozy/simpl`

## What Simpl feels like

Simpl is dynamically typed, expression-oriented, and heavily built around calls.
Functions, lists, strings, integers, and records can all participate in a unified
"call-shaped" style, which gives the language a compact and composable surface.

Example:

```simpl
let greet(name; age = 18) =
  "Hello, "name" ("$age")";

greet("Alice")
```

Example with patterns and structured branching:

```simpl
let describe value =
  if value is
  | #Ok(x) and x > 0 then "positive"
  | #Ok(0) then "zero"
  | #Err(msg) then msg
  else "unknown";

describe(#Ok(3))
```

## Feature Summary

- integers, booleans, strings, `nil`, lists, records, variants, and references
- first-class functions with lexical closures
- pattern matching in `let`, function parameters, and `if ... is`
- `let`, `let and`, `let rec`, and mutually recursive `let rec ... and ...`
- trailing application: `f x`, `f(1; 2) 3`
- named arguments and default parameters
- `with` sugar for passing a trailing lambda
- record field access plus UFCS-style fallback (`x.foo` -> `foo(x)`)
- expression-based string interpolation using string calls and `$`
- source-positioned parse/runtime errors

## Install Requirements

- [MoonBit](https://docs.moonbitlang.com)

## Quick Start

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
moon run cmd/main -- path/to/program.simpl
```

## CLI

The interpreter entry point is [`cmd/main/main.mbt`](cmd/main/main.mbt).

```text
simpl [options] [path]
```

Options:

- `-e`, `--eval <source>`: evaluate an inline source string
- `-f`, `--file <path>`: read source from a file
- `-p`, `--parse`: parse only and print the surface AST

Rules:

- `--eval` cannot be combined with file input
- `--file` and positional file input cannot be combined
- if no input is provided, the CLI prints help

The CLI also supports multi-block input. A line containing at least three dashes
such as `---` splits the source into separate blocks, each evaluated or parsed
independently.

## Language Tour

### Literals

```simpl
1
true
"hello"
nil
[1; 2; 3]
{x = 1; y = 2}
#Some(1)
```

### Functions and Calls

```simpl
let inc(x) = x + 1;
let add x = fn y = x + y;

inc(41)
inc 41
add 1 2
```

Parameters are separated by semicolons inside parentheses, and default values are
allowed after required parameters:

```simpl
let greet(name; title = "friend") = "Hi, "title" "name;
greet("MoonBit")
greet(name = "MoonBit"; title = "team")
```

### Patterns

Patterns work in bindings, function parameters, and `if ... is` branches:

```simpl
let [head; ..tail] = [1; 2; 3];
let {name; age} = {name = "Ada"; age = 20};
let unwrap(#Some(x)) = x;
```

Supported pattern forms:

- variable binders and `_`
- literal patterns
- variant patterns
- list patterns and rest patterns
- record patterns
- alternatives with `|`

### Structured `if`

Simpl uses a split-style conditional syntax rather than a separate `match`
keyword.

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

Nested refinement uses `and`, and inner split groups can be closed with `or`:

```simpl
if input is
| #Some(x) and
  | x > 10 then "big"
  | x == 10 then "edge"
  or
else "small"
```

### References

```simpl
let r = ref 1;
do r += 41;
!r
```

Reference operators:

- read: `!r`
- assign: `r := value`
- update: `+=`, `-=`, `*=`, `/=`, `%=`, `&&=`, `||=`

### Records and UFCS

```simpl
let point = {x = 1; y = 2};
point.x
```

If a record field does not exist, field syntax can fall back to a function call:

```simpl
let inc x = x + 1;
41.inc
```

and:

```simpl
let add3(x; y; z) = x + y + z;
1.add3(2; 3)
```

### String Composition

Simpl does not have template literals. Instead, it relies on:

- string calls
- trailing application
- unary `$` to convert values to text

```simpl
let name = "Alice";
let age = 18;
name" is "$age" years old"
```

### Callable Non-Functions

Some values have call behavior:

- `3("ha")` repeats a string
- `3([1; 2])` repeats a list
- `3(fn() = 1)` calls the function three times and collects results
- `[10; 20; 30](1)` indexes a list
- `[1; 2; 3](fn x = x * 2)` maps over a list
- `", "([1; 2; 3])` joins values with a separator
- `{x = 1}(x = 2; y = 3)` returns an updated record

## Built-in Functions

Current built-ins:

- `ref(value)`
- `say(value)`
- `map(list; f)`
- `length(value)`
- `max(a; b)` or `max(list)`
- `min(a; b)` or `min(list)`
- `sum(list)`

Built-ins do not accept named arguments.

## Library API

Public entry points:

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

Exposed types:

- `SurfaceExpr`
- `Value`

## Documentation Map

- [Language overview](docs/language.md)
- [Functions and calls](docs/functions-and-calls.md)
- [Conditionals](docs/conditionals.md)
- [Data, patterns, and mutation](docs/data-patterns-and-mutation.md)
- [Composition patterns](docs/composition-patterns.md)

## Repository Layout

- [`simpl.mbt`](simpl.mbt): core AST, runtime values, evaluator
- [`parser.mbt`](parser.mbt): parser and diagnostics
- [`lexer.mbt`](lexer.mbt): lexer and source spans
- [`desugar.mbt`](desugar.mbt): surface-to-core lowering
- [`pattern.mbt`](pattern.mbt): pattern logic and truthiness helpers
- [`apply.mbt`](apply.mbt): call semantics and built-ins
- [`pretty.mbt`](pretty.mbt): pretty-printing
- [`cmd/main/main.mbt`](cmd/main/main.mbt): CLI
- [`simpl_test.mbt`](simpl_test.mbt): black-box tests
- [`simpl_wbtest.mbt`](simpl_wbtest.mbt): white-box tests

## Development Notes

Recommended validation loop:

```powershell
moon test
moon info
moon fmt
```

If an intentional behavior change updates snapshot output:

```powershell
moon test --update
```

## License

Apache-2.0. See [`LICENSE`](LICENSE).
