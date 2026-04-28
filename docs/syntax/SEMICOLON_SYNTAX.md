# Semicolon Syntax in Simpl

This document describes the exact role of `;` in Simpl.

## 1. Design Principle

In Simpl, `;` is a grammar-level separator. It is **not** a general "end of statement" token.

Use `;` only where the grammar explicitly requires it.

## 2. Required Positions

### 2.1 Binding/effect forms

A semicolon separates the head form from its body expression.

```simpl
let x = 1; x + 1
let rec fact(n) = if n == 0 then 1 else n * fact(n - 1); fact(5)
do say("hello"); 42
with(v) = use(41); v + 1
with run(); 42
```

For multi-binding forms, `and` separates bindings, and one final `;` starts the shared body.

```simpl
let a = 1 and b = 2; a + b
let rec f(x) = x and g(y) = y; f(1)
```

### 2.2 Function parameter lists

Parameters are semicolon-separated.

```simpl
fn(x; y) = x + y
fn(a; b = 2; c = 3) = a + b + c
```

### 2.3 Call argument lists

Arguments are semicolon-separated.

```simpl
f(1; 2)
f(x = 1; 2; y = 3)
```

### 2.4 List literals

List items are semicolon-separated.

```simpl
[1; 2; 3]
[#Left(1); #Right(2)]
```

### 2.5 Record literals

Record fields are semicolon-separated.

```simpl
{x = 1; y = 2}
{x; y = 2}
```

### 2.6 Patterns

List and record patterns also use semicolon separation.

```simpl
let [x; y] = [1; 2]; x + y
let {x; y = z} = {x = 1; y = 2}; x + z
```

List-rest patterns keep semicolons as part of the pattern shape.

```simpl
let [head; ..rest] = [1; 2; 3]; head
let [a; ..; z] = [1; 2; 3]; z
```

## 3. Invalid Uses

### 3.1 Standalone trailing semicolon

```simpl
1 + 2;   // parse error
```

### 3.2 Trailing separator inside grouped syntax

Simpl does not allow trailing `;` before a closing token.

```simpl
f(1; 2;)        // invalid
fn(x; y;) = x   // invalid
[1; 2;]         // invalid
{x = 1; y = 2;} // invalid
```

## 4. Practical Reading Rule

- In grouped syntax, read `;` as "next item".
- In `let` / `let rec` / `do` / `with`, read `;` as "then evaluate body".

## 5. Summary

- `;` is required in many structured forms.
- `;` separates items (params, args, list elements, record fields, pattern parts).
- `;` also separates head and body in binding/effect forms.
- `;` is not a universal statement terminator.
