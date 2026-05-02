# 04. Data and Mutation

This page focuses on the data forms you will use most often: lists, records,
variants, equality, and references.

## Lists

List literals use semicolons:

```simpl
[1; 2; 3]
```

Lists work naturally with patterns:

```simpl
let [x; y] = [1; 2];
let [head; ..tail] = [1; 2; 3];
let [first; ..middle; last] = [1; 2; 3; 4];
```

## Records

Record literal:

```simpl
{x = 1; y = 2}
```

Field shorthand:

```simpl
let x = 1;
let y = 2;
{x; y}
```

Field access:

```simpl
point.x
```

Record pattern with renaming:

```simpl
let {x; y = renamed} = point;
```

## Variants

Variants carry a tag and one payload:

```simpl
#Some(1)
#Err("bad")
```

They are especially useful with `if ... is`:

```simpl
if result is
| #Ok(value) then value
| #Err(message) then message
else nil
```

## Structural equality

`==` compares values structurally.

```simpl
[1; 2] == [1; 2]
{x = 1; y = 2} == {x = 1; y = 2}
#Some(1) == #Some(1)
```

The paired operator `!=` checks structural inequality.

## References

References are mutable cells:

```simpl
let r = ref 1;
!r
```

Assignment:

```simpl
r := 3
```

Compound updates:

```simpl
r += 1
r -= 1
r *= 2
r /= 2
r %= 5
r &&= expr
r ||= expr
```

These update forms are expressions and return the new stored value.

## `!` has two meanings

If the operand is a reference, `!` dereferences it:

```simpl
!r
```

Otherwise, it behaves as logical not using Simpl truthiness:

```simpl
!false
!nil
!1
```

## `do`

`do` is useful when you want an effect before continuing with another
expression:

```simpl
let r = ref 0;
do r += 1;
!r
```

You can read it as a convenient form of "evaluate this, ignore its value, then
continue".

## A small stateful example

```simpl
let counter = ref 0;
let tick() =
  do counter += 1;
  !counter;

[tick(); tick(); tick()]
```

The next page covers the broader composition model that makes lists, strings,
integers, and records feel callable.
