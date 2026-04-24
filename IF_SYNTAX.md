# Simpl `if` Syntax

This document defines the current `if` syntax in Simpl.

## Scope

Simpl implements a focused subset of [*The Ultimate Conditional Syntax*](https://cse.hkust.edu.hk/~parreaux/publication/oopsla24b/) with exactly three split points:

- `if`
- `is`
- `and`

Supported control tokens:

- branch introducer: `|`
- branch body introducer: `then`
- fallback: `else`
- fallback sugar: `end` (equivalent to `else nil`)
- split-closure token: `or`

`or` is a split-closure token, not a branch.

## Core model

A conditional is built from nested split points. Conceptually:

```simpl
if ... is ... and ... then ... else ...
```

can be viewed as:

```simpl
if
| ... is
  | ... and
    | ... then ...
    or
  or
else ...
```

Each split point can host multiple branches.

## Branch and fallback sugar

- In an `if` split, `else e` is sugar for `| true then e`.
- In an `and` split, `else e` is sugar for `| true then e`.
- In an `is` split, `else e` is sugar for `| _ then e`.
- `end` is sugar for `else nil` at the split point it closes.

In practical code, prefer `else` over explicit fallback branches because it is clearer and closes the current split directly.

## `if` single-route vs multi-route

`if` is in **single-route mode** iff all of the following hold:

1. the first branch has no leading `|`, and
2. that first branch is an `is` split, and
3. that `is` split is **multi-route** (its first pattern branch starts with `|`).

In all other cases, `if` is in **multi-route mode**.

## Split mode (`is` and `and`)

`is` and `and` follow the same mode rule:

- if the first nested branch starts with `|`, the split is **multi-route**;
- otherwise, it is **single-route**.

In multi-route mode, branches attach until closed by one of:

- `else`
- `end`
- `or`

## Closure and nesting

`else`, `end`, and `or` always apply to the current open split point.

- `or` closes the current split point.
- `else` and `end` close the current split point with fallback semantics.
- after an inner split closes, parsing continues at the enclosing split.

## Examples

### Compact one-line style

```simpl
if x > 0 then x else -x
```

### Multi-way `if`

```simpl
if
| n < 0 then "neg"
| n == 0 then "zero"
else "pos"
```

### `if` with first branch as multi-route `is`

```simpl
if value is
| #Left(#Some(x)) then x
| #Right(y) then y
else 0
```

### `if` with mixed branch forms

```simpl
if
| f(value) is #Left(x) then x
| f > 2 then 2
else -1
```

### Single-route `and`

```simpl
if score > 0 and score < 100 then score else 0
```

### Multi-route `and` with `or`

```simpl
if
| ready and
  | has_cache then "cache"
  | has_network then "network"
  or
| ready then "pending"
else "idle"
```

### Multi-route `and` with `else` fallback

```simpl
if flag and
  | cond_a then 1
  else 2
else 3
```

### Pattern refinement with `and ... is`

```simpl
if user is #Some(u) and u.role is 
  | #Admin(_) then "admin"
  else u.name
else "guest"
```

### OCaml vs Simpl (split-merge)

OCaml style (same head repeated across guarded cases):

```ocaml
match input with
| Some a when a > 10 -> "big"
| Some a when a = 10 -> "edge"
| _ -> "small"
```

Simpl split-merge style (shared head once, inner split for guard branches):

```simpl
if input is #Some(a) and
  | a > 10 then "big"
  | a == 10 then "edge"
  or
else "small"
```

### Nested split composition

```simpl
if
| f(x) is #Some(y) and
  | y > 0 then y
  | y == 0 then 0
  else -1
| x > 0 then x
else 0
```

## Notes

- indentation and newlines are formatting only; tokens define syntax.
- boolean operators are `&&` and `||`.
- the word token `or` is reserved for split closure.
