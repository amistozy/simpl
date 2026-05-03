# 04. Data And Mutation

Simpl has structural data, explicit mutable references, and a small set of
built-ins for common list and numeric work.

## Lists

List literals use semicolons:

```simpl
[1; 2; 3]
```

Lists concatenate with `+` and repeat with `*`:

```simpl
[1; 2] + [3; 4]
[1; 2] * 3
3 * [1; 2]
```

Non-positive repetition returns an empty list.

Lists destructure naturally:

```simpl
let [x; y] = [1; 2];
let [head; ..tail] = [1; 2; 3];
let [first; ..middle; last] = [1; 2; 3; 4];
```

## Records

Record literals use named fields:

```simpl
{x = 1; y = 2}
```

Field shorthand uses the variable name as the field name:

```simpl
let x = 1;
let y = 2;
{x; y}
```

Functions can be stored as fields:

```simpl
let r = {inc(x) = x + 1};
r.inc(41)
```

Field access reads fields and supports chaining:

```simpl
{user = {name = "Moon"}}.user.name
```

Record patterns can bind or rename fields:

```simpl
let {x; y = renamed} = point;
```

## Record Updates

Records are callable with named arguments. The result is a new record with
updated or added fields.

```simpl
let point = {x = 1; y = 2};
let moved = point(x = 3; z = 4);
moved
```

The original record is not mutated.

Record calls reject positional arguments.

## Variants

Variants have a tag and one payload:

```simpl
#Some(1)
#Err("bad")
#Pair([10; 32])
```

They are usually consumed with `if ... is`:

```simpl
if result is
| #Ok(value) then value
| #Err(message) then message
else nil
```

## Equality

`==` and `!=` use structural equality for values such as lists, records, and
variants.

```simpl
[1; [2; 3]] == [1; [2; 3]]
{x = 1; y = 2} == {y = 2; x = 1}
#Some(1) != #Some(2)
```

## References

References are mutable cells:

```simpl
let r = ref 1;
!r
```

Assignment returns the new stored value:

```simpl
let x = r := 3;
!r + x
```

Compound reference updates:

```simpl
r += 1
r -= 1
r *= 2
r /= 2
r %= 5
r &&= expr
r ||= expr
```

`&&=` and `||=` short-circuit using Simpl truthiness.

## `!` For References And Logic

If the operand is a reference, `!` dereferences it:

```simpl
!r
```

For any non-reference value, `!` is logical not:

```simpl
!false -- true
!nil   -- true
!1     -- false
```

## Built-Ins

Current built-ins:

- `ref(value)` creates a reference
- `say(value)` prints a value and returns `nil`
- `map(list; f)` maps a list without flattening
- `filter(list; f)` keeps items whose predicate result is truthy
- `fold(list; init; f)` folds from the left
- `length(value)` accepts strings and lists
- `reverse(value)` accepts strings and lists
- `max(a; b)` or `max(list)` accepts integers
- `min(a; b)` or `min(list)` accepts integers
- `sum(list)` sums an integer list

Built-ins do not accept named arguments.

Most built-ins work well with UFCS:

```simpl
[1; 2; 3].sum
"moon".length
"moon".reverse
[1; 2; 3].reverse
[3; 5; 2].max
```

Continue with [05 - Callable Composition](./05-composition-patterns.md).
