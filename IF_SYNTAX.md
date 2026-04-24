# Simpl `if` Syntax

This document defines the current `if` syntax in Simpl.

## Scope

Simpl implements a focused subset of *The Ultimate Conditional Syntax* with exactly three split points:

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

## `if` single-route vs multi-route

`if` is in **single-route mode** iff all of the following hold:

1. the first branch has no leading `|`, and
2. that first branch is an `is` split, and
3. that `is` split is **multi-route** (its first pattern branch starts with `|`).

In all other cases, `if` is in **multi-route mode**.

## `is` split mode

- If the first `is` branch starts with `|`, it is multi-route.
- Otherwise, it is single-route.

In multi-route `is`, branches attach until closed by one of:

- `else`
- `end`
- `or`

## `and` split mode

- If the first `and` branch starts with `|`, it is multi-route.
- Otherwise, it is single-route.

In multi-route `and`, branches attach until closed by one of:

- `else`
- `end`
- `or`

## Closure and nesting

`else`, `end`, and `or` always apply to the current open split point.

- `or` closes the current split point.
- `else` and `end` close the current split point with fallback semantics.
- After an inner split closes, parsing continues at the enclosing split.

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
| #Left(x) then x
| _ then 0
end
```

### `if` with mixed branch forms

```simpl
if
| #Left(1) is #Left(x) then x
| true then 0
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
| true then "wait"
else "idle"
```

### Multi-route `and` with `else` fallback

```simpl
if flag and
| cond_a then 1
else 2
end
```

### Pattern refinement with `and ... is`

```simpl
if user is
| #Some(u) and u.role is #Admin(_) then "admin"
| #Some(u) then u.name
else "guest"
```

### Nested split composition

```simpl
if
| #Some(x) is
  | #Some(y) and
    | y > 0 then y
    | y == 0 then 0
    or
  | _ then -1
  or
| true then 42
else 0
```

## Notes

- Indentation and newlines are formatting only; tokens define syntax.
- Boolean operators are `&&` and `||`.
- The word token `or` is reserved for split closure.
