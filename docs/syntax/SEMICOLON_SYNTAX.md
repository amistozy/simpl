# Simpl Semicolon Syntax

This document defines how `;` is used in Simpl.

## 1. Core Rule

In Simpl, semicolon is primarily a **separator**, not a universal statement terminator.

You can think of it as:

- separating items inside grouped syntax (lists, records, params, args, patterns)
- connecting a binding/effect expression to its following body in `let` / `do`

## 2. Where `;` Is Used

### 2.1 In `let`, `let rec`, and `do`

A semicolon is required between the binding/effect part and the body expression.

```simpl
let x = 1; x + 1
let rec fact(n) = if n == 0 then 1 else n * fact(n - 1); fact(5)
do print(1); 42
```

Notes:

- `let ... and ...` uses the keyword `and` between bindings, then one `;` before the body.
- `let rec ... and ...` behaves the same way.

### 2.2 In function parameter lists

Parameters are separated by semicolons.

```simpl
fn(x; y) = x + y
fn(a; b = 2; c = 3) = a + b + c
```

### 2.3 In call argument lists

Arguments are separated by semicolons.

```simpl
f(1; 2)
f(a = 1; 2; c = 3)
```

### 2.4 In list literals

List items are separated by semicolons.

```simpl
[1; 2; 3]
[#Left(1); #Right(2)]
```

### 2.5 In record literals

Record fields are separated by semicolons.

```simpl
{x = 1; y = 2}
{x; y = 2}
```

### 2.6 In list and record patterns

Pattern items/fields also use semicolon separation.

```simpl
let [x; y] = [1; 2]; x + y
let {x; y = z} = {x = 1; y = 2}; x + z
```

For list-rest patterns, semicolon is also part of the rest form:

```simpl
let [head; ..rest] = [1; 2; 3]; head
let [a; ..; z] = [1; 2; 3]; z
```

## 3. Important Non-Uses

### 3.1 Not a global expression terminator

A top-level trailing semicolon is not valid by itself:

```simpl
1 + 2;   // parse error
```

### 3.2 No trailing semicolon in grouped lists

These forms are invalid:

```simpl
f(1; 2;)        // invalid
fn(x; y;) = x   // invalid
[1; 2;]         // invalid
{x = 1; y = 2;} // invalid
```

Simpl expects another item after `;`, or the proper closing token without a trailing separator.

## 4. Practical Style

- Use `;` exactly where grammar requires separation.
- Do not add optional-looking trailing semicolons.
- In `let` / `do`, read `;` as “then evaluate the body”.

## 5. Quick Summary

- `;` is required in many structured forms.
- `;` separates parameters, arguments, list items, and record fields.
- `;` connects `let` / `let rec` / `do` to their body expression.
- `;` is not a standalone “end-of-statement” marker.
