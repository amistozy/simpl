# 01. Language Tour

This page gives a fast overview of what Simpl is and how code tends to look.

## Core ideas

Simpl is:

- dynamically typed
- expression-oriented
- pattern-friendly
- centered around a broad notion of "calling"

You can think of it as a small language where values compose through a compact,
consistent syntax.

## Runtime values

Simpl currently supports:

- integers
- booleans
- strings
- `nil`
- lists
- records
- variants
- references
- functions

Examples:

```simpl
1
true
"hello"
nil
[1; 2; 3]
{x = 1; y = 2}
#Some(1)
```

## Expressions all the way down

Simpl programs are built from expressions rather than statements.

```simpl
let x = 41; x + 1
do say("hello"); 42
```

Semicolons separate parts of a larger expression. They are not just line-ending
punctuation.

## Operators

Arithmetic:

- `+`
- `-`
- `*`
- `/`
- `%`
- `^`

Comparison:

- `==`
- `!=`
- `<`
- `<=`
- `>`
- `>=`

Logical operators:

- `&&`
- `||`

Unary operators:

- `~x`: integer negation
- `!x`: dereference for refs, logical not otherwise
- `$x`: convert a value to display text

## Truthiness

Only two values are falsey:

- `false`
- `nil`

Everything else is truthy. That rule is used by `if`, `&&`, `||`, logical `!`,
and reference updates such as `&&=` and `||=`.

## Comments

Simpl supports single-line comments:

```simpl
-- this is ignored
let x = 1; -- this part too
x + 1
```

## A representative example

```simpl
let render(result) =
  if result is
  | #Ok({name; score}) and 
    | score >= 60 then name": pass ("$score")"
    else name": retry ("$score")"
  | #Err(message) then message
  else "unknown";

render #Ok({name = "Mina"; score = 72})
```

## What to read next

If you want to understand the language quickly, continue with:

- [02 - Functions and Calls](./02-functions-and-calls.md)
- [03 - Control Flow and Patterns](./03-control-flow-and-patterns.md)
- [05 - Composition Patterns](./05-composition-patterns.md)
