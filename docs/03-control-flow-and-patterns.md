# 03. Control Flow and Patterns

Simpl uses one pattern family across bindings, parameters, and conditional
refinement. That consistency is one of the language's strongest ideas.

## `let`

Basic binding:

```simpl
let x = 41; x + 1
```

Multiple independent bindings:

```simpl
let a = 1
and b = 2;
a + b
```

Recursive bindings:

```simpl
let rec even(n) =
  if n == 0 then true else odd(n - 1)
and odd(n) =
  if n == 0 then false else even(n - 1);

even(10)
```

## Patterns in bindings

Patterns work directly in `let`:

```simpl
let [head; ..tail] = [1; 2; 3];
let {name; age} = {name = "Ada"; age = 20};
let #Ok(x) as whole = #Ok(1);
```

## `if`

Simpl uses a split-style conditional syntax.

Simple form:

```simpl
if x > 0 then x else ~x
```

Multi-branch form:

```simpl
if
| n < 0 then "neg"
| n == 0 then "zero"
else "pos"
```

Conditions use Simpl truthiness, not strict boolean-only checking.

## `guard`

Simpl also provides a compact guard form:

```simpl
guard ready;
"ok"
```

```simpl
guard value is #Some(x) else 0;
x
```

It desugars as:

- `guard cond; body` => `if cond then body end`
- `guard cond else fallback; body` => `if cond then body else fallback`

The condition part reuses the single-route conditional head syntax, so it can
contain ordinary conditions, `is`, and nested `and` refinement:

```simpl
guard score > 0 and score < 100 else 0;
score
```

```simpl
guard xs is [x; ..rest] and x > 0 else 0;
x
```

`guard` is intentionally a single-branch construct. It does not open its own
multi-route `| ... then ...` split.

## `if ... is`

Pattern-directed branching lives inside `if ... is`.

```simpl
if value is
| #Left(x) then x
| #Right(y) then y
else 0
```

This replaces the need for a separate `match` keyword.

## Refinement with `and`

`and` opens a nested refinement step after an outer branch has already matched.

```simpl
if user is
| #Some(u) and u.role is
  | #Admin(_) then "admin"
  else u.name
else "guest"
```

It also works with ordinary expressions:

```simpl
if score > 0 and score < 100 then score else 0
```

## Closing a nested split with `or`

Inside this syntax, `or` is not the boolean operator. It closes the current
nested split and returns to the enclosing one.

```simpl
if input is
| #Some(x) and
  | x > 10 then "big"
  | x == 10 then "edge"
  or
else "small"
```

For ordinary boolean logic, use `&&` and `||`.

## `else` and `end`

- `else expr` gives the fallback branch
- `end` is shorthand for `else nil`

```simpl
if ready then "ok" end
```

## Supported pattern forms

Simpl patterns currently include:

- variable binders
- `_`
- literal patterns
- `as`-patterns
- variant patterns
- list patterns
- list-rest patterns
- record patterns
- alternatives with `|`

Examples:

```simpl
let unwrap(#Some(x) | #Ok(x)) = x;
let {name; age = years} = person;
let [first; ..middle; last] = values;
```

## Reading tip

When an `if` looks large, read it from the outside in:

1. find the current split
2. read each `| ... then ...` arm
3. treat `and`, `or`, `else`, and `end` as structure markers

That mental model makes the syntax much easier to follow.
