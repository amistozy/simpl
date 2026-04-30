# Simpl Function Syntax

This document describes function syntax and call behavior in Simpl.

## 1. Function Definitions

Simpl supports both explicit lambda binding and function-definition sugar:

```simpl
let inc = fn(x) = x + 1;
let inc(x) = x + 1;
```

`name(params) = body` is sugar for `name = fn(params) = body`.

This sugar works in assignment-like positions (for example record fields and named call arguments):

```simpl
let box = { inc(x) = x + 1 };
apply(f(x) = x + 1)
```

## 2. Lambda Forms

General lambda form:

```simpl
fn(params) = body
```

Single-parameter shorthand:

```simpl
fn x = body
```

Examples:

```simpl
fn(x) = x + 1
fn(x; y) = x + y
fn(a; b = 2; c = 3) = a + b + c
```

## 3. Parameters

Parameters are separated by `;`.

A parameter may be:

- a pattern parameter (for example `x`, `#Pair(x)`, `{name}`)
- a parameter with a default value (`param = expr`)

Example:

```simpl
fn(#Pair(x); {y}; z = 3) = x + y + z
```

Ordering rule:

- required parameters must come before defaulted parameters

Valid:

```simpl
fn(a; b; c = 1; d = 2) = ...
```

Invalid:

```simpl
fn(a = 1; b) = ...
```

## 4. Default Values

Default expressions are evaluated when the function is defined (captured in closure environment), not at call time.

```simpl
let r = ref(1);
let f(x = !r) = x;
do r := 2;
f()   // => 1
```

## 5. Parenthesized Calls

Standard call form:

```simpl
f(...)
```

Arguments are separated by `;`.

Supported argument forms:

- positional: `expr`
- named: `name = expr`
- named-lambda sugar: `name(params) = body` (same as `name = fn(params) = body`)
- single-param named-lambda sugar: `name x = body` (same as `name = fn x = body`)

Examples:

```simpl
f(1; 2)
f(a = 1; c = 3)
f(a = 1; 2; c = 3)
apply(f(x) = x + 1)
apply(f x = x + 1)
```

## 6. Trailing Application

Simpl supports trailing-argument call syntax:

- `func arg` means `func(arg)`
- `func(...) arg` means `func(...; arg)`

Examples:

```simpl
inc 41
add3(1; 2) 3
```

When trailing application would otherwise capture too little, `:(expr)` can be
used as an explicit grouped argument. It is equivalent to `expr`.

```simpl
say: (1 + 2) * 3
// same as: say((1 + 2) * 3)
```

This style is also what enables expression-based string interpolation chains.

## 7. `with` Lambda Sugar

`with` appends a lambda as the last argument of a target call.

Forms:

- `with(params) = target; body` -> `target(fn(params) = body)`
- `with x = target; body` -> `target(fn x = body)`
- `with target; body` -> `target(fn() = body)`

Example:

```simpl
with(x) = map([1; 2; 3]); x + 1
// same as: map([1; 2; 3]; fn(x) = x + 1)
```

## 8. Precedence and Associativity

Trailing application is parsed at a low-precedence stage and associates to the right.

So:

```simpl
f g x
```

parses as:

```simpl
f(g(x))
```

This is why patterns like `foo fn(x) = ...` work naturally:

```simpl
let foo(f) = f 42;
foo fn(x) = x + 1
```

## 9. Runtime Argument Binding

At call time, Simpl binds arguments in this order:

1. Bind named arguments by parameter name.
2. Bind positional arguments left-to-right to remaining unbound parameters.
3. Fill unbound parameters with stored default values.
4. If a required parameter is still unbound, raise an arity error.

Common runtime errors:

- `unknown named argument: <name>`
- `duplicate argument: <name>`
- arity mismatch (too many/few arguments)

## 10. UFCS Interaction

Simpl supports UFCS-style fallback:

- `x.foo` may evaluate as `foo(x)`
- `x.foo(y; z)` may evaluate as `foo(x; y; z)`

For records, direct field lookup is tried first. If no field exists, UFCS fallback is attempted.

## 11. Quick Summary

- Define functions with `fn(...) = ...` or `name(...) = ...` sugar.
- Put required params before defaulted params.
- Defaults are captured at definition time.
- Calls support positional and named arguments.
- Trailing application (`f x`) and `with` sugar are first-class call syntax.
