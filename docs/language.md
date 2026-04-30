# Simpl Language Overview

Simpl is a small dynamic language with an expression-first design.

Everything in the language is built around a few consistent ideas:

- expressions produce values
- patterns appear in bindings, parameters, and conditional refinement
- calls are more general than "calling a function"
- compact syntax is preferred over large keyword-heavy forms

## Core Values

Simpl has these runtime value kinds:

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

## Expressions, Not Statements

Simpl programs are made from expressions. Sequencing is explicit and usually
appears through binding-style forms:

```simpl
let x = 1; x + 1
do say("hello"); 42
```

Semicolons are structural separators, not generic statement terminators.

## Variables and Functions

Bindings use `let`:

```simpl
let x = 41; x + 1
```

Functions are first-class values and support concise definition forms:

```simpl
let inc(x) = x + 1;
let add x = fn y = x + y;
```

Closures capture the lexical environment where they are created.

## The Operator Set

Arithmetic:

- `+`
- `-`
- `*`
- `/`
- `%`

Comparison:

- `==`
- `!=`
- `<`
- `<=`
- `>`
- `>=`

Short-circuiting logical operators:

- `&&`
- `||`

Unary operators:

- `~x`: integer negation
- `!x`: dereference if `x` is a reference, otherwise logical not
- `$x`: convert a value to its display string

Two runtime edge cases are part of the language behavior:

- `a / 0` evaluates to `0`
- `a % 0` evaluates to `a`

## Truthiness

Truthiness is simple:

- `false` is falsey
- `nil` is falsey
- everything else is truthy

That rule is used by:

- `if`
- `&&`
- `||`
- non-reference `!`
- reference updates `&&=` and `||=`

## Records, Variants, and Lists

Records:

```simpl
{name = "Ada"; age = 20}
```

Variants:

```simpl
#Ok(1)
#Err("bad")
```

Lists:

```simpl
[1; 2; 3]
```

These values are deeply integrated into pattern matching and call behavior.

## References

Mutable cells are created with `ref`:

```simpl
let r = ref 1;
do r += 2;
!r
```

Reference syntax:

- `r := value`
- `r += value`
- `r -= value`
- `r *= value`
- `r /= value`
- `r %= value`
- `r &&= value`
- `r ||= value`

## What Makes Simpl Distinct

The most unusual part of Simpl is that several non-function values are callable.

Examples:

- strings can concatenate or join
- lists can index, batch-index, or map
- integers can repeat strings/lists or repeatedly invoke a function
- records can accept named arguments to build an updated record

That means the language often reads like a uniform "compose values by calling"
system instead of a collection of unrelated special forms.

## Built-ins

The current built-in names are:

- `ref`
- `say`
- `map`
- `length`
- `max`
- `min`
- `sum`

They shape a lot of the examples in the rest of the docs, especially `ref`,
`say`, `map`, and `length`.
