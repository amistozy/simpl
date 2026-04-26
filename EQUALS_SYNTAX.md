# Simpl `=` Syntax

This document explains how the single equals sign `=` is used in Simpl.

## 1. Quick Meaning

In Simpl, `=` is used for **definition-style binding and specification**, not for mutation and not for equality testing.

Use:

- `==` for equality comparison
- `:=` for reference assignment (mutation)

## 2. Where `=` Is Valid

## 2.1 `let` bindings

`let` uses `=` to bind a pattern to a value expression.

```simpl
let x = 1; x + 1
let [a; b] = [10; 32]; a + b
let {x = left; y = right} = {x = 10; y = 32}; left + right
```

## 2.2 Function definitions

Function definitions place `=` between parameter list and body.

```simpl
let add(x; y) = x + y; add(1; 2)
let add = fn(x; y) = x + y; add(1; 2)
fn(x) = x + 1
```

For `let rec`, each function definition also uses `=`.

```simpl
let rec even(n) = if n == 0 then true else odd(n - 1)
and odd(n) = if n == 0 then false else even(n - 1);
even(10)
```

## 2.3 Default parameter values

In parameter lists, `=` introduces a default value.

```simpl
fn(a; b = 2; c = 3) = a + b + c
```

Default values are evaluated at function definition time.

## 2.4 Named call arguments

In call sites, `name = expr` passes a named argument.

```simpl
f(a = 1; c = 3)
f(a = 1; 2; c = 3)
```

Named-argument lambda sugar is also supported:

```simpl
apply(f(x) = x + 1)
```

Builtins do not accept named arguments.

## 2.5 Record literals

In record literals, `=` assigns a field value.

```simpl
{x = 1; y = 2}
{x; y = 2}   // shorthand field `x` plus explicit field `y`
```

Record fields can also use function sugar:

```simpl
{inc(x) = x + 1}
```

## 2.6 Record patterns

In record patterns, `field = pattern` maps a field to a custom binding pattern.

```simpl
let {x = left; y = right} = {x = 10; y = 32}; left + right
```

Without `=`, record-pattern shorthand binds the same name:

```simpl
let {x; y} = {x = 10; y = 32}; x + y
```

## 3. What `=` Does Not Mean

## 3.1 Not equality

This is wrong for comparison:

```simpl
if x = 1 then 2 else 3   // invalid
```

Use:

```simpl
if x == 1 then 2 else 3
```

## 3.2 Not mutation

This does not update a reference:

```simpl
r = 3   // invalid
```

Use:

```simpl
r := 3
```

## 4. Related Operators

- `=`: binding/specification in syntax forms
- `==`: equality comparison expression
- `:=`: reference assignment
- `+=`, `-=`, `*=`, `/=`, `%=`, `&&=`, `||=`: reference update operators (and `let` compound-binding sugar)

## 5. Summary

- Think of `=` as “define/bind/specify”.
- Use `==` for checking equality.
- Use `:=` (or update operators) for mutation.
