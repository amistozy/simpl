# Simpl Function Syntax

This document describes function syntax and call behavior in Simpl.

## Function Forms

Simpl supports three equivalent function-definition styles:

```simpl
let f = fn(x) = x + 1; f(41)
let f(x) = x + 1; f(41)
let box = { inc(x) = x + 1 }; box.inc(41)
```

The second and third forms are syntax sugar over assigning a lambda:

- `f(x) = body` is sugar for `f = fn(x) = body`

This sugar applies in places where assignment to a named slot is valid (for example, `let` bindings, record fields, and named call arguments).

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

## Parameter Rules

Parameters are separated with `;`.

### Required vs defaulted parameters

- Required parameter: `x`
- Defaulted parameter: `x = expr`

Example:

```simpl
fn(y; x = 1; z = 3) = x + y + z
```

### Ordering constraint

Required parameters must come before defaulted parameters.

Valid:

```simpl
fn(a; b; c = 1; d = 2) = ...
```

Invalid:

```simpl
fn(a = 1; b) = ...
```

### No implicit `nil` for required params

If a required parameter is not provided at call time, evaluation fails with an arity error. Required parameters are never auto-filled with `nil`.

### Default evaluation timing

Default expressions are evaluated when the function is defined, not when it is called.

That means defaults are effectively captured values:

```simpl
let r = ref(1);
let f(x = !r) = x;
do r := 2;
f()        // still uses 1
```

### Default expressions cannot reference parameters

Since defaults are evaluated at definition time, parameter names are not yet bound. So parameter-to-parameter default references are invalid:

```simpl
fn(a = 1; b = a + 1) = b    // invalid at runtime
```

## Call Syntax

Calls use:

```simpl
f(args...)
```

Arguments are separated with `;`.

Supported argument forms:

- Positional: `expr`
- Named: `name = expr`

Examples:

```simpl
f(1; 2)
f(a = 1; c = 3)
f(a = 1; 2; c = 3)
```

## Argument Matching Rule

Simpl matches call arguments in this order:

1. Match all named arguments first.
2. Match remaining positional arguments left-to-right to the remaining unbound parameters.
3. Fill still-unbound parameters from stored defaults.
4. If any required parameter remains unbound, raise an arity error.

## UFCS Interaction

Simpl supports Uniform Function Call Syntax (UFCS):

- `x.foo` behaves like `foo(x)` when UFCS fallback applies.
- `x.foo(y; z)` behaves like `foo(x; y; z)` when UFCS fallback applies.

For records, direct field access has priority:

- If record `x` has field `foo`, use the field.
- Else, if environment has callable `foo`, use UFCS fallback.
- Else, report `missing field`.

