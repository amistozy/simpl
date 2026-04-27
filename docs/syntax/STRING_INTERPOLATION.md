# Simpl String Interpolation (Current Behavior)

This document describes how to build interpolated strings in **current Simpl**.

Simpl does not have a dedicated template string syntax. Instead, interpolation is built from:

- trailing application (`f x`)
- string-call semantics (`"a"(...)`)
- unary `$` (value to display string)

## 1. Core Idea

If a value is a `String`, calling it with one positional argument behaves specially:

- `string(other_string)` => concatenation
- `string(list)` => join list items with `string` as the separator

Because trailing calls are supported, this gives a chainable interpolation style.

## 2. Basic Interpolation Pattern

Use string fragments as callees and convert non-string values with `$`:

```simpl
let name = "Alice";
let age = 18;
name" is "$age" years old"
```

Result:

```simpl
"Alice is 18 years old"
```

You can also start from a literal:

```simpl
let name = "Carol";
"Hello, "name"!"
```

## 3. What `$` Does

`$expr` converts a value to Simpl's display string (pretty form).

```simpl
$1          // "1"
$true       // "true"
$[1; 2]     // "[1; 2]"
${x; y}     // "{x = 1; y = 2}"   (if x,y are in scope)
```

Grouping forms such as `$(...)`, `$[...]`, and `${...}` work because `$` is a unary operator applied to the next expression.

## 4. Important Difference: String Values

`$` on a string includes quotes in the output, because it uses display formatting:

```simpl
let name = "Alice";
"hello "$name
// => "hello "Alice""
```

For plain text insertion of an existing string variable, pass the string directly (without `$`):

```simpl
let name = "Alice";
"hello "name
// => "hello Alice"
```

## 5. Precedence Note

Trailing application has very low precedence, so:

```simpl
"value=" $1 + 2
```

is interpreted like:

```simpl
"value="($1 + 2)
```

This still leads to a type error (`String + Int`) inside the argument expression (`$1 + 2`).
Use parentheses to convert the full arithmetic expression first:

```simpl
"value=" $(1 + 2)
```

## 6. Common Errors

Passing a non-string/non-list directly to a string call:

```simpl
"value=" 1
```

Runtime error:

```text
string call expected String or List, got Int(1)
```

## 7. Summary

- Interpolation is expression-based, not template-literal-based.
- Use direct string chaining for string values.
- Use `$` to insert non-string values (or debug-style string representations).
- Use `$(...)` to control grouping in mixed expressions.
