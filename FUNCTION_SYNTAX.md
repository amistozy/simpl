# Simpl Function Syntax

This document is the canonical reference for function-related syntax in **Simpl**.

## 1. Function Definition Forms

Simpl supports two equivalent forms for named functions:

```simpl
let inc = fn(x) = x + 1;
let inc(x) = x + 1;
```

`name(params) = body` is syntax sugar for `name = fn(params) = body`.

The same sugar is available in any assignment-like slot:

```simpl
let box = { inc(x) = x + 1 };
let apply(f(x) = x + 1) = f(41);
apply()
```

In the second example, `f(x) = x + 1` means `f = fn(x) = x + 1`.

## 2. Lambda Syntax

Anonymous functions always use:

```simpl
fn(params) = body
```

Examples:

```simpl
fn(x) = x + 1
fn(x; y) = x + y
fn(a; b = 2; c = 3) = a + b + c
```

## 3. Parameters

Parameters are separated by `;`.

- Required parameter: `x`
- Defaulted parameter: `x = expr`
- Pattern parameter: any valid pattern, for example `#Pair(x)` or `{name}`

Example:

```simpl
fn(#Pair(x); {y}; z = 3) = x + y + z
```

### Parameter Ordering Rule

All required parameters must appear before any defaulted parameter.

Valid:

```simpl
fn(a; b; c = 1; d = 2) = ...
```

Invalid:

```simpl
fn(a = 1; b) = ...
```

### Default Evaluation Time

Default expressions are evaluated when the function is defined, not when it is called.

```simpl
let r = ref(1);
let f(x = !r) = x;
do r := 2;
f()   // => 1
```

Because defaults are pre-evaluated, defaults cannot depend on parameter names:

```simpl
fn(a = 1; b = a + 1) = b   // runtime error when called
```

## 4. Call Syntax

### Parenthesized Calls

Standard call form:

```simpl
f(args...)
```

Arguments are separated by `;`.

Supported argument forms:

- Positional: `expr`
- Named: `name = expr`
- Named lambda sugar: `name(params) = body` (same as `name = fn(params) = body`)
- Single-param named lambda sugar: `name param = body` (same as `name = fn param = body`)

Examples:

```simpl
f(1; 2)
f(a = 1; c = 3)
f(a = 1; 2; c = 3)
apply(f(x) = x + 1)
apply(f x = x + 1)
```

### Trailing-Argument Calls

Simpl also supports trailing application:

- `func expr` means `func(expr)`
- `func(...) expr` means `func(...; expr)`

Examples:

```simpl
inc 41           // inc(41)
add3(1; 2) 3     // add3(1; 2; 3)
```

### With-Lambda Sugar

`with` appends a lambda as the last argument to a target call:

- `with(params) = func(args); body` -> `func(args; fn(params) = body)`
- `with x = func(args); body` -> `func(args; fn x = body)`
- `with func(args); body` -> `func(args; fn() = body)`

### Precedence and Associativity

Trailing application has the lowest precedence among expression forms and is right-associative.

So:

```simpl
f g x
```

is parsed as:

```simpl
f(g(x))
```

This enables trailing-lambda style:

```simpl
let foo(f) = f 42;
foo fn(x) = x + 1
```

## 5. Argument Binding Semantics

At runtime, argument-to-parameter binding happens in this order:

1. Bind all named arguments by parameter name.
2. Bind positional arguments from left to right to remaining unbound parameters.
3. Fill any still-unbound parameters using stored default values.
4. If a required parameter is still unbound, raise an arity error.

Runtime errors are raised for:

- unknown named argument
- duplicate assignment to the same parameter
- too many provided arguments

## 6. UFCS and Function Calls

Simpl supports UFCS-style fallback:

- `x.foo` may evaluate as `foo(x)`
- `x.foo(y; z)` may evaluate as `foo(x; y; z)`

For records, direct field access takes priority:

1. If record `x` has field `foo`, use the field.
2. Otherwise, if callable `foo` exists in scope, use UFCS fallback.
3. Otherwise, report a missing field / undefined function error.

## 7. Summary

- Use `fn(params) = body` for lambdas. For a single non-default parameter, `fn x = body` is also allowed.
- Use `name(params) = body` where assignment sugar is allowed.
- Put required parameters before defaulted ones.
- Defaults are captured at definition time.
- Calls support positional + named arguments, plus trailing application.
- UFCS provides method-like call style without changing core function semantics.
