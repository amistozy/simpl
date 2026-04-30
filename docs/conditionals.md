# Conditionals

Simpl uses a split-style conditional system built from `if`, `is`, and `and`.

It does not use a separate `match` keyword.

## Basic `if`

Simple conditional:

```simpl
if x > 0 then x else ~x
```

Multi-branch conditional:

```simpl
if
| n < 0 then "neg"
| n == 0 then "zero"
else "pos"
```

`if` conditions use truthiness, not a strict "must be Bool" rule.

## Pattern Refinement with `is`

`is` checks a value against patterns:

```simpl
if value is
| #Left(x) then x
| #Right(y) then y
else 0
```

This is the main branching mechanism for variant-heavy code.

## Refinement with `and`

`and` opens a nested split that only runs after the outer branch has already
succeeded.

Example:

```simpl
if user is
| #Some(u) and u.role is
  | #Admin(_) then "admin"
  else u.name
else "guest"
```

Another example with ordinary conditions:

```simpl
if score > 0 and score < 100 then score else 0
```

## The Meaning of `or`

`or` inside this syntax is not the logical operator.

The logical operators are:

- `&&`
- `||`

The keyword `or` closes the current nested split and returns control to the
enclosing one.

```simpl
if input is
| #Some(x) and
  | x > 10 then "big"
  | x == 10 then "edge"
  or
else "small"
```

## `else` and `end`

- `else expr` gives the fallback branch for the current split
- `end` is shorthand for `else nil`

Example:

```simpl
if ready then "ok" end
```

This returns `"ok"` when the condition is truthy and `nil` otherwise.

## Reading Nested Conditionals

The easiest way to read a large conditional is:

1. identify the current split keyword
2. read each `| ... then ...` branch inside it
3. treat `or`, `else`, and `end` as delimiters for that split
4. then move back outward

## Important Constraint

`if ... is ...` is a conditional form, not a general-purpose infix expression.
Pattern matching in Simpl lives inside the split-style conditional system.

## Why This Design Matters

The syntax is compact, but it is also expressive enough to cover:

- normal conditionals
- variant dispatch
- guard-style refinement
- nested decision trees

without needing separate `if`, `match`, and guard constructs.
