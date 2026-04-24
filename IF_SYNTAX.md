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

`or` is **not** a branch. It only closes the current split point.

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

- In an `if` split, `else e` is sugar for an extra branch `| true then e`.
- In an `and` split, `else e` is sugar for `| true then e`.
- In an `is` split, `else e` is sugar for `| _ then e`.
- `end` is sugar for `else nil` at the split point it closes.

## `if` single-route vs multi-route

### Rule

`if` is in **single-route mode** iff all of the following hold:

1. the first branch has no leading `|`, and
2. that first branch is an `is` split, and
3. that `is` split is **multi-route** (its first pattern branch starts with `|`).

In all other cases, `if` is **multi-route mode**.

### Consequences

- `if` multi-route mode must be closed by `else` or `end`.
- `if` single-route mode does not attach later outer `| ...` branches.

## `is` split mode

- If the first `is` branch starts with `|`, it is multi-route.
- Otherwise, it is single-route.

In multi-route `is`, branches attach until the split is closed by one of:

- `else`
- `end`
- `or`

If multi-route `is` is used as the first branch of `if` under the single-route rule above, that closed `is` branch forms the whole `if` body (outer `if` does not continue with additional branches).

## `and` split mode

- If the first `and` branch starts with `|`, it is multi-route.
- Otherwise, it is single-route.

In multi-route `and`, branches attach until closed by:

- `else`
- `end`
- `or`

Important: `else` closes only the current `and` split. It does **not** automatically consume the outer `if` closure.

## Closure precedence and nesting

`else`, `end`, and `or` always apply to the **current open split point**.

- `or` only closes the current split point.
- `else`/`end` close the current split point with fallback semantics.
- After closing an inner split, parsing continues at the enclosing split.

## Valid examples

### `if` multi-route

```simpl
if
| true then 1
| false then 2
else 0
```

### `if` single-route (special case)

```simpl
if #Some(1) is
| #Some(x) then x
| _ then 0
end
```

### `and` else closes `and`, `end` closes outer `if`

```simpl
if true and
| false then 1
else 2
end
```

### `or` closes current split only

```simpl
if
| true and
  | false then 1
  | true then 2
  or
| true then 3
else 0
```

## Invalid example

`and` closed, but outer `if` still open:

```simpl
if true and
| false then 1
| true then 2
end
```

This is invalid because `end` closes the `and` split here, while the outer `if` (multi-route) still lacks `else/end`.

## Notes

- Indentation and newlines are formatting only; tokens define syntax.
- Boolean operators are `&&` and `||`.
- The word token `or` is reserved for split closure and is not a boolean operator.
