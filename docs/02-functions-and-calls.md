# 02. Functions and Calls

Functions are central in Simpl, but call syntax is intentionally broader than
"call a function". This page starts with ordinary functions and then moves into
the language's more unusual call behavior.

## Defining functions

Lambda form:

```simpl
fn(x; y) x + y
```

Binding sugar:

```simpl
let add(x; y) = x + y;
```

Functions are closures and capture the lexical environment where they are
created.

## Parameters

Parameters are separated by semicolons. A parameter can be:

- a name
- a destructuring pattern
- a parameter with a default value

Examples:

```simpl
fn(x; y) x + y
fn({name}; title = "friend") title" "name
fn([head; ..tail]) head
```

## Default arguments

Default expressions are evaluated when the call happens.

```simpl
let r = ref 1;
let f(x = !r) = x;
do r := 2;
f()
```

This returns `2`, not `1`.

Defaults can also refer to earlier parameters:

```simpl
let pair(a = 1; b = a + 1) = [a; b];
pair()
```

## Calling functions

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

Named arguments are matched first. Remaining positional arguments then fill the
open parameter slots from left to right.

## Trailing application

Simpl supports low-precedence trailing application:

```simpl
f x
f(1; 2) 3
```

This gives the language a pipeline-like feel without adding a dedicated pipe
operator.

Trailing application associates to the right:

```simpl
f g x
```

This means:

```simpl
f(g(x))
```

## Grouping with `:(...)`

Use `:(...)` when you need to make the trailing argument boundary explicit.

```simpl
say: (1 + 2) * 3
```

This is especially useful around infix expressions and `fn expr`.

```simpl
[1; 20; 3]
.map(fn: (_ + 1) * 2)
.filter(fn _ < 10)
```

## `fn expr` eta-expansion

Simpl supports an explicit shorthand introduced by `fn`.

```simpl
fn 42
fn _
fn _ + 1
fn _ * 2 + _
```

These behave like:

```simpl
fn() 42
fn(x) x
fn(x) x + 1
fn(x; y) x * 2 + y
```

Rules of thumb:

- no underscore means a zero-parameter lambda
- each underscore becomes a fresh parameter
- bare `_` is only valid when consumed by `fn expr`

## `with`

`with` is sugar for passing a lambda as the final argument of a call target.

```simpl
with(x) = use(41); x + 1
```

This means:

```simpl
use(41; fn(x) x + 1)
```

Other supported forms:

```simpl
with x = use(41); x + 1
with run; 42
```

## UFCS-style fallback

Field access can fall back to a same-named function call when the receiver is
not a record field lookup that succeeds.

```simpl
let inc(x) = x + 1;
41.inc
```

```simpl
let add3(x; y; z) = x + y + z;
1.add3(2; 3)
```

Real record fields still take priority over this fallback.

## Common call-time errors

Because calls are used so widely in Simpl, these failures are important to keep
in mind:

- wrong arity
- duplicate named arguments
- unknown named arguments
- parameter pattern mismatch
- trying to call a value that is not callable

The next docs explain the data and control-flow forms that often appear inside
those calls.
