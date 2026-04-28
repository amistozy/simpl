# String Interpolation in Simpl

Simpl does not provide template literals. Instead, interpolation is built from ordinary expressions:

- trailing application (`f x`)
- string-call behavior (`"text"(arg)`)
- unary `$` for value-to-text conversion

## Overview

When a `String` value is called with one argument, it has special behavior:

- `s(t)` where `t` is `String` -> concatenate
- `s(xs)` where `xs` is `List` -> join list items with `s` as the separator

Because trailing application is supported, this creates a natural interpolation chain.

## Basic Usage

```simpl
let name = "Alice";
let age = 18;
"Name: "name", age: "$age
```

This evaluates to:

```simpl
"Name: Alice, age: 18"
```

String fragments and values can be mixed directly:

```simpl
let user = "Carol";
"Hello, "user"!"
```

## `$` Conversion Rules

`$expr` converts an expression into interpolation text:

- if `expr` is already `String`, it is kept as-is
- otherwise, Simpl uses pretty-display output

Examples:

```simpl
$1          // "1"
$true       // "true"
$[1; 2]     // "[1; 2]"
$"moon"     // "moon"
```

Since `$` is unary, it applies to the next expression. Parenthesized and bracketed forms are valid:

```simpl
$(1 + 2)
$[1; 2; 3]
${x; y}
```

## String Values and `$`

For string values, these are equivalent:

```simpl
let name = "Alice";
"hello "name
"hello "$name
```

Both produce `"hello Alice"` (without extra quotes around `name`).

## Precedence and Grouping

Trailing application has low precedence. This matters in mixed expressions.

```simpl
"value=" $1 + 2
```

This is parsed as:

```simpl
"value="($1 + 2)
```

So the inner expression fails (`String + Int`). Use grouping when you intend arithmetic first:

```simpl
"value=" $(1 + 2)   // "value=3"
```

## Common Pitfall

Passing a non-string value directly to a string call is invalid:

```simpl
"value=" 1
```

Runtime error:

```text
string call expected String or List, got Int(1)
```

## Relation to `say`

`say(v)` uses the same conversion policy as `$v`:

- strings are emitted as raw text
- other values use pretty-display text

This keeps printed output and interpolation behavior consistent.

## Quick Reference

- Interpolation is expression-based, not template-literal-based.
- Chain string fragments and values via trailing application.
- Use `$` for non-string values (and optionally for strings).
- Use `$(...)` when combining interpolation with operators.
