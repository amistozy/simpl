# Simpl `if` Syntax (Current UCS)

This document describes the current conditional syntax in Simpl.

## Overview

Simpl uses a unified conditional style (UCS) centered on:

- `if` for boolean-guard branching
- `if ... is` for pattern-based branching
- `and` / `and ... is` for guard refinements inside a branch
- `else` and `end` for branch closure (`end` means `else nil`)
- `or` only as a UCS guard-attachment terminator (not a boolean operator)

Indentation and line breaks are not semantic.

## 1. `if` (boolean multi-way)

Multi-way form (Haskell/Kotlin style):

```simpl
if
| cond1 then expr1
| cond2 then expr2
else expr3
```

The first branch pipe is optional. So these are also valid:

```simpl
if cond then then_expr else else_expr
```

```simpl
if cond then
  then_expr
else
  else_expr
```

You can use `end` instead of `else ...` as sugar for `else nil`:

```simpl
if
| cond1 then expr1
| cond2 then expr2
end
```

## 2. `if ... is` (pattern split)

`if ... is` works like pattern matching:

```simpl
if value is
| pattern1 then expr1
| pattern2 then expr2
else fallback_expr
```

The first branch pipe is optional:

```simpl
if value is pattern then expr else fallback
```

`end` is allowed and means `else nil`:

```simpl
if value is
| pattern1 then expr1
| pattern2 then expr2
end
```

## 3. `and` (guard refinement)

`and` attaches an extra condition to a branch.

### 3.1 Single-route `and`

If the branch after `and` does **not** start with `|`, it is single-route:

```simpl
if
| condA and condB then expr1
| condC then expr2
else expr3
```

No `else`/`end`/`or` is required to close this `and` node.

### 3.2 Multi-route `and`

If the first `and` branch starts with `|`, it is multi-route:

```simpl
if
| outerCond and
  | guard1 then expr1
  | guard2 then expr2
  else exprElse
| otherCond then exprOther
else exprFinal
```

A multi-route `and` node is closed by one of:

- `else ...`
- `end` (sugar for `else nil`)
- `or` (close current `and` attachment and continue outer branches)

Example with `or`:

```simpl
if x is
| #Left(y) and
  | y < 0 then 0
  | y > 10 then 1
  or
| #Right(y) and y < 0 then 2
else 3
```

## 4. `and ... is` (pattern refinement inside a branch)

`and ... is` is the pattern-split counterpart of `and`.

Single-route:

```simpl
if v is
| #Left(x) and f(x) is #Ok(y) then y
| #Right(x) and x > 0 then x
else 42
```

Multi-route:

```simpl
if v is
| #Left(x) and f(x) is
  | #Ok(y) then y
  | #Err(_) then 0
  else -1
| #Right(x) and x > 0 then x
else 42
```

Like multi-route `and`, multi-route `and ... is` is closed by `else`, `end`, or `or`.

## 5. Operators and reserved words

- Boolean operators are `&&` and `||`.
- `or` is **not** a boolean operator; it is reserved for UCS guard-node closure.
- `is` is used in UCS (`if ... is`, `and ... is`) as conditional pattern syntax.

## 6. Design notes

- Newline and indentation are formatting only; token structure defines parsing.
- For OCaml-like style:
  - single-line forms usually omit the first `|`
  - multi-line branch groups usually keep the first `|` for alignment
