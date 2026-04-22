# simpl

A small interpreter-style language implemented in MoonBit.

## Features

- Dynamic values
- Function syntax (`fn`, closures, higher-order functions)
- Environment-based lexical scoping
- Recursive descent parser
- Records without prior type definitions
- Variants without prior type definitions

## Syntax

- Values: `Int`, `Bool`, `String`, `nil`, lists, closures, records, variants
- Expressions:
  - literals and variables
  - `let ... = ... in ...`
  - `let rec f(...) = ... in ...`
  - `if ... then ... else ...`
  - `fn(...) => ...`
  - `match e { #Left(x) => ..., #Right(y) => ..., [x, #Right(z)] => ... }`
  - `match` cases may include guards: `#Some(x) if x > 0 => ...`
  - patterns support bindings, `_`, literals, records, lists, `..rest` and bare `..` list slices, nested variants, and `|`
  - `let` bindings and function parameters reuse the same pattern syntax
  - references: `ref e`, `!e`, `e1 := e2`
  - records: `{a: 1, b: 2}`, `e.a`, `let {a, b} = e in ...`
  - lists: `[1, 2, 3]`
  - variants: `#Left(1)`, `#Right("x")`
  - sequencing: `e1; e2`
  - function call: `f(x, y)`
  - unary ops: `-x`, `not x`
  - binary ops: `+ - * / == != < <= > >= and or && ||`

## Examples

```moonbit nocheck
///|
let expr = @simpl.add(@simpl.int_lit(1), @simpl.int_lit(2))

///|
let value = @simpl.eval(expr) // VInt(3)
```

```moonbit nocheck
///|
let value = @simpl.eval_source("1 + 2 * 3") // VInt(7)
```

```moonbit nocheck
///|
let value = @simpl.eval_source(
  "let p = {x: 10, y: 32} in let {x, y} = p in x + y",
)
```

```moonbit nocheck
///|
let value = @simpl.eval_source(
  "match #Left(41) { #Left(x) => x + 1, #Right(y) => y }",
)
```

## Public API

- Evaluation:
  - `eval(expr) -> Value raise`
  - `eval_with_env(expr, env) -> Value raise`
- Parsing:
  - `parse(source) -> Expr raise`
  - `format_parse_error(error) -> String`
  - `parse_error_text(source) -> String?`
  - `eval_source(source) -> Value raise`
- Constructors:
  - `record(fields) -> Expr`
  - `list(items) -> Expr`
  - `variant(tag, value) -> Expr`
  - `let_record_in(bindings, value_expr, body) -> Expr`
  - `let_pattern_in(pattern, value_expr, body) -> Expr`
  - `match_cases(value_expr, cases) -> Expr`
  - `match_case_clauses(value_expr, cases) -> Expr`
  - `match_variant(value_expr, cases) -> Expr`
  - `match_list(value_expr, cases) -> Expr`
  - `pbind(name) -> MatchPattern`
  - `pint(value) -> MatchPattern`
  - `pbool(value) -> MatchPattern`
  - `pstring(value) -> MatchPattern`
  - `pnil() -> MatchPattern`
  - `por(patterns) -> MatchPattern`
  - `pvariant(tag, pattern) -> MatchPattern`
  - `plist(items) -> MatchPattern`
  - `plist_rest(prefix, rest_name, suffix) -> MatchPattern`
  - `precord(fields) -> MatchPattern`
  - `lambda_patterns(params, body) -> Expr`
  - `let_rec_patterns_in(name, params, func_body, body) -> Expr`
- Test helpers:
  - `eval_is_int / eval_is_bool / eval_is_string / eval_is_error`
  - `parse_is_ok / parse_is_error`
  - `eval_source_is_int / eval_source_is_bool / eval_source_is_string / eval_source_is_error`

## Current limits

- Strings do not yet support escape sequences.
- There are no statement blocks yet.

## Semantics

- `and` / `&&` and `or` / `||` are short-circuit expressions that return the actual operand value.
- Records are structural values backed by maps.
- Variants are tagged values with one payload.
