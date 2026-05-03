# 02. Functions And Calls

Functions are first-class closures, but Simpl's call syntax is broader than
"invoke a function". This page starts with functions and then explains the call
forms that make the rest of the language feel compact.

## Lambdas

```simpl
fn(x; y) x + y
```

Lambdas capture their lexical environment:

```simpl
let x = 10;
let add_x(y) = x + y;
let x = 100;
add_x(5) -- 15
```

## Function Binding Sugar

These two forms are equivalent:

```simpl
let add = fn(x; y) x + y;
```

```simpl
let add(x; y) = x + y;
```

Recursive functions use `let rec`:

```simpl
let rec fact(n) =
  if n == 0 then 1 else n * fact(n - 1);

fact(5)
```

Mutually recursive functions use `let rec ... and ...`:

```simpl
let rec even(n) =
  if n == 0 then true else odd(n - 1)
and odd(n) =
  if n == 0 then false else even(n - 1);

even(10)
```

## Parameters

Parameters are separated by semicolons. A parameter can be a name, a pattern, or
a parameter with a default value.

```simpl
fn(x; y) x + y
fn({name}; title = "friend") title" "name
fn([head; ..tail]) head
```

Defaults are evaluated when the call happens, not when the function is created:

```simpl
let r = ref 1;
let f(x = !r) = x;
do r := 2;
f() -- 2
```

Defaults can refer to earlier parameters:

```simpl
let pair(a = 1; b = a + 1) = [a; b];
pair() -- [1; 2]
```

Required parameters are best placed before defaulted parameters. The parser
allows some unusual orders, but invalid calls fail at runtime.

## Positional And Named Arguments

```simpl
f(1; 2)
f(x = 1; y = 2)
f(x = 1; 2; z = 3)
```

Named arguments are matched first. Remaining positional arguments fill open
parameter slots from left to right.

Named function-valued arguments have a shortcut:

```simpl
apply(f(x) = x + 1)
```

That is the same idea as:

```simpl
apply(f = fn(x) x + 1)
```

## Trailing Application

Simpl supports low-precedence trailing application:

```simpl
f x
f(1; 2) 3
```

`f(1; 2) 3` appends `3` to the same call, so it behaves like:

```simpl
f(1; 2; 3)
```

Trailing application associates to the right:

```simpl
f g x
```

means:

```simpl
f(g(x))
```

Use parentheses when you want a nested call result instead:

```simpl
(f 2) 3
```

## Colon Grouping

`:(...)` makes the trailing argument boundary explicit.

```simpl
say: (1 + 2) * 3
```

This passes the whole multiplication expression to `say`.

It is especially helpful with `fn expr`:

```simpl
[1; 20; 3]
.map(fn: (_ + 1) * 2)
.filter(fn _ < 10)
```

## `fn expr` Eta-Expansion

`fn` can introduce a full lambda or eta-expand an expression with underscore
placeholders.

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

Rules:

- no underscore creates a zero-argument lambda
- each underscore creates a fresh parameter from left to right
- bare `_` is only valid when it is consumed by `fn expr`

## `with`

`with` appends a lambda as the final argument of a call target.

```simpl
with(v) use(41);
v + 1
```

means:

```simpl
use(41; fn(v) v + 1)
```

Zero-argument forms are supported:

```simpl
with run;
42
```

which means:

```simpl
run(fn() 42)
```

## Field Access And UFCS Fallback

Field access first tries to read a record field.

```simpl
{x = 1; y = 2}.x
```

If the receiver is not a record with that field, Simpl tries a same-named
function in the environment and passes the receiver as the first argument.

```simpl
let inc(x) = x + 1;
41.inc -- inc(41)
```

```simpl
let add3(x; y; z) = x + y + z;
1.add3(2; 3) -- add3(1; 2; 3)
```

Actual record fields take priority over this fallback.

## Common Call Errors

Calls can fail because of:

- wrong arity
- duplicate named arguments
- unknown named arguments
- parameter pattern mismatch
- attempting to call a value that is not callable

Continue with [03 - Control Flow and Patterns](./03-control-flow-and-patterns.md).
