# 01. Language Tour

Simpl is a small dynamic language where expressions and calls do most of the
work. A program is a single expression, and larger programs are built by
sequencing expression forms with semicolons.

```simpl
let x = 41;
x + 1
```

## Values

The runtime value set is intentionally small:

```simpl
1
true
"hello"
nil
[1; 2; 3]
{name = "Ada"; score = 42}
#Some(1)
ref 0
fn(x) x + 1
```

Lists, records, and argument lists use semicolons as separators. Commas are not
part of the surface syntax.

## Everything Is An Expression

`let`, `do`, `guard`, `if`, and `with` all produce values.

```simpl
let answer = 41;
answer + 1
```

```simpl
do say "warming up";
42
```

```simpl
if ready then "go" else "wait"
```

A top-level trailing semicolon supplies `nil` as the final body.

```simpl
let x = 1;
```

## Comments

Single-line comments start with `--`.

```simpl
-- a full-line comment
let x = 1; -- an end-of-line comment
x + 1
```

## Operators

Arithmetic:

- `+`, `-`, `*`, `/`, `%`, `^`

Comparison:

- `==`, `!=`, `<`, `<=`, `>`, `>=`

Logical:

- `&&`, `||`

Unary:

- `~x` negates an integer
- `!x` dereferences a reference, or logically negates a non-reference value
- `$x` converts a value to display text

Power binds tighter than multiplication and is right-associative:

```simpl
2 ^ 3 ^ 2 -- 512
```

Division by zero returns `0`. Modulo by zero returns the dividend.

## Truthiness

Only `false` and `nil` are falsey. Everything else is truthy.

That rule is used by `if`, `guard`, `&&`, `||`, logical `!`, `filter`, and
reference updates such as `&&=` and `||=`.

`&&` and `||` short-circuit and return the actual selected operand:

```simpl
"left" && "right"  -- "right"
nil || "fallback"  -- "fallback"
```

## Strings And Display

Strings support common escapes such as `\n`, `\t`, `\"`, `\\`, and `\r`.

`$` returns the pretty display form of a value:

```simpl
$42        -- "42"
$"moon"    -- "\"moon\""
$[1; 2]    -- "[1; 2]"
$#Some(1)  -- "#Some(1)"
```

String interpolation is ordinary call chaining:

```simpl
let name = "Alice";
let age = 18;
name" is "$age" years old"
```

Use grouped `$` forms when the expression is not a single atom:

```simpl
"sum="$(1 + 2)", list="$[1; 2]", record="${x = 1}
```

## A Representative Example

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

## Next

Continue with [02 - Functions and Calls](./02-functions-and-calls.md).
