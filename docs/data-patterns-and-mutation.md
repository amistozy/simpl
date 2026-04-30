# Data, Patterns, and Mutation

This page collects the parts of Simpl that shape everyday data manipulation:

- list syntax
- record syntax
- variant syntax
- pattern matching
- references and updates
- structural equality

## Lists

List literals use semicolons:

```simpl
[1; 2; 3]
```

Lists are also used heavily in patterns:

```simpl
let [x; y] = [1; 2]; x + y
let [head; ..tail] = [1; 2; 3]; head
```

List-rest patterns can bind the middle slice:

```simpl
let [a; ..rest; z] = [1; 2; 3; 4]
```

## Records

Record literals:

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

Record patterns:

```simpl
let {x; y = renamed} = point; x + renamed
```

## Variants

Variants carry a tag and one payload:

```simpl
#Some(1)
#Err("bad")
```

They work naturally with pattern matching:

```simpl
if result is
| #Ok(value) then value
| #Err(msg) then msg
else nil
```

## Patterns Everywhere

Simpl reuses one pattern family across:

- `let`
- function parameters
- `if ... is`

Available pattern forms include:

- binders like `x`
- wildcard `_`
- literal patterns
- variant patterns
- list patterns
- list-rest patterns
- record patterns
- alternatives with `|`

This consistency is one of the language's strongest design choices.

## Equality

Structural equality uses `==`.

It works across:

- integers
- booleans
- strings
- `nil`
- lists
- records
- variants

Examples:

```simpl
[1; 2] == [1; 2]
{x = 1; y = 2} == {x = 1; y = 2}
#Some(1) == #Some(1)
```

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

Updates:

```simpl
r += 1
r -= 1
r *= 2
r /= 2
r %= 5
r &&= expr
r ||= expr
```

The update operators are expressions and return the new stored value.

## `!` Has Two Roles

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

## `=` vs `==` vs `:=`

These three spellings have different meanings:

- `=` defines or specifies structure
- `==` compares values
- `:=` mutates a reference

That distinction is central to reading Simpl correctly.
