# Functions and Calls

Functions are central in Simpl, but the call syntax is intentionally broader than
just "function invocation".

## Defining Functions

Full lambda form:

```simpl
 fn(x; y) x + y
```

Binding sugar:

```simpl
let inc(x) = x + 1;
```

These sugared forms define ordinary closures.

## Parameters

Parameters are separated by semicolons.

A parameter can be:

- a simple binder
- a destructuring pattern
- a parameter with a default value

Examples:

```simpl
fn(x; y) x + y
fn({name}; title = "friend") title" "name
fn([head; ..tail]) head
```

Required parameters must come before optional ones.

## Default Arguments

Defaults are evaluated when the call happens and only for parameters that were
not explicitly provided.

```simpl
let r = ref 1;
let f(x = !r) = x;
do r := 2;
f()
```

This returns `2`.

Because defaults are evaluated during argument binding, they can refer to
earlier parameters that have already been bound:

```simpl
let f(a = 1; b = a + 1) = b;
f()
```

This returns `2`.

The same rule also means recursive functions can use recursive bindings inside
default expressions:

```simpl
let rec f(x = f(1)) = x;
f()
```

## Calling Functions

Regular call syntax:

```simpl
f(1; 2)
```

Named arguments:

```simpl
f(x = 1; y = 2)
```

Mixed calls:

```simpl
f(x = 1; 2; z = 3)
```

Named arguments bind first. Positional arguments then fill the remaining
parameters from left to right.

## Trailing Application

Simpl supports low-precedence trailing application:

```simpl
f x
f(1; 2) 3
```

This gives the language a compact, pipeline-like surface without introducing a
special pipeline operator.

Trailing application associates to the right:

```simpl
f g x
```

is read as:

```simpl
f(g(x))
```

## Grouping with `:`

When trailing application would capture too little, `:(...)` can be used to
force the intended argument shape.

```simpl
say: (1 + 2) * 3
```

This is especially useful in string composition or around infix expressions.

It can also disambiguate the body of `fn expr` eta-expansion when the intended
function body should include a larger infix expression:

```simpl
[1; 20; 3]
.map(fn: (_ + 1) * 2)
.filter(fn _ < 10)
```

Without `:()`, `fn _ + 1 * 2` would bind the body differently. Grouping makes
the eta-expanded body explicit.

## `with`

`with` is call sugar that passes a lambda as the final argument of a target
expression.

```simpl
with(x) = target; body
```

means:

```simpl
target(fn(x) body)
```

Other forms:

```simpl
with x = target; body
with target; body
```

The zero-parameter form is useful for repeated effects and deferred blocks.

## Named Lambda Sugar

Inline function definitions also work inside named arguments and record fields.

Examples:

```simpl
apply(f(x) = x + 1)
let r = {inc(x) = x + 1}
```

This keeps higher-order code compact without adding a separate anonymous-method
syntax.

## `fn expr` Eta-Expansion

Simpl supports an explicit eta-expansion shorthand introduced by `fn`.

Examples:

```simpl
fn 42
fn _ + 1
fn _
fn _ * 2 + _
```

These expand like:

```simpl
fn() 42
fn(x) x + 1
fn(x) x
fn(x; y) x * 2 + y
```

Rules:

- if the body contains no `_`, `fn expr` becomes a zero-parameter lambda
- if the body contains `_`, each `_` becomes a fresh parameter from left to right
- bare `_` is only valid when consumed by `fn expr`
- the shorthand works anywhere an expression is allowed
- `:()` can be used to make the intended `fn expr` body explicit

## UFCS-Style Fallback

Field syntax can fall back to same-named function calls:

```simpl
let inc(x) = x + 1;
41.inc
```

and:

```simpl
let add3(x; y; z) = x + y + z;
1.add3(2; 3)
```

Records still prefer real fields when a field exists, and UFCS fallback only
uses actual function values.

## Errors at Call Time

Common failures include:

- unknown named arguments
- duplicate arguments
- arity mismatches
- parameter pattern mismatches
- calling a value that is not callable

Those behaviors matter because call syntax is used so widely throughout Simpl.
