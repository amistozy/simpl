# Simpl Function Syntax

This document describes function definition and call syntax in Simpl.

## Function Forms

Simpl supports these equivalent ways to define functions:

```simpl
let f = fn(x) = x + 1; f(41)
let f(x) = x + 1; f(41)
let box = { inc(x) = x + 1 }; box.inc(41)
```

`name(params) = body` is sugar for `name = fn(params) = body`.

This sugar is available where assigning to a named slot is valid, including:

- `let` bindings
- record fields
- named call arguments

## Lambda Syntax

Anonymous functions use:

```simpl
fn(params) = body
```

Examples:

```simpl
fn(x) = x + 1
fn(x; y) = x + y
fn(a; b = 2; c = 3) = a + b + c
```

## Parameters

Parameters are separated by `;`.

- Required parameter: `x`
- Defaulted parameter: `x = expr`

Example:

```simpl
fn(y; x = 1; z = 3) = x + y + z
```

### Ordering Rule

All required parameters must come before all defaulted parameters.

Valid:

```simpl
fn(a; b; c = 1; d = 2) = ...
```

Invalid:

```simpl
fn(a = 1; b) = ...
```

### Default Evaluation Time

Default expressions are evaluated when the function is defined (not when called).

```simpl
let r = ref(1);
let f(x = !r) = x;
do r := 2;
f()        // still uses 1
```

Because defaults are evaluated at definition time, they cannot reference parameter names:

```simpl
fn(a = 1; b = a + 1) = b    // runtime error
```

## Call Syntax

### Parenthesized Calls

Standard calls use:

```simpl
f(args...)
```

Arguments are separated by `;`.

Supported argument forms:

- positional: `expr`
- named: `name = expr`

Examples:

```simpl
f(1; 2)
f(a = 1; c = 3)
f(a = 1; 2; c = 3)
```

### Trailing-Argument Calls

Simpl also supports trailing-argument call sugar:

- `func expr` means `func(expr)`
- `func(...) expr` means `func(...; expr)`

Examples:

```simpl
inc 41            // inc(41)
add3(1; 2) 3      // add3(1; 2; 3)
```

### Precedence and Associativity of Trailing Calls

Trailing-argument calls are:

- lowest precedence among expression forms
- right-associative

So:

```simpl
f g x
```

is parsed as:

```simpl
f(g(x))
```

This also enables trailing lambda style:

```simpl
let foo(f) = f 42;
foo fn(x) = x + 1
```

which behaves like:

```simpl
foo(fn(x) = x + 1)
```

## Argument Matching

When calling a function, Simpl binds arguments in this order:

1. Bind named arguments first.
2. Bind positional arguments left-to-right to remaining unbound parameters.
3. Fill remaining parameters from stored defaults.
4. If any required parameter is still unbound, raise an arity error.

## UFCS Interaction

Simpl supports UFCS fallback:

- `x.foo` behaves like `foo(x)` when UFCS fallback applies.
- `x.foo(y; z)` behaves like `foo(x; y; z)` when UFCS fallback applies.

For records, direct field access has priority:

- If record `x` has field `foo`, use that field.
- Otherwise, if environment contains callable `foo`, use UFCS fallback.
- Otherwise, report a missing-field error.
