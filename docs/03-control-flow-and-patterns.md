# 03. Control Flow And Patterns

Simpl uses one pattern family across `let`, function parameters, `guard`, and
`if ... is`. That keeps destructuring and branching consistent.

## `let`

Basic binding:

```simpl
let x = 41;
x + 1
```

Parallel binding:

```simpl
let x = 10;
let x = 1 and y = x + 1;
y -- 11
```

Right-hand sides in `let ... and ...` are evaluated in the outer environment,
then the resulting bindings are added together.

Compound binding sugar:

```simpl
let x = 1;
let x += 41;
x
```

Supported compound forms are `+=`, `-=`, `*=`, `/=`, `%=`, `&&=`, and `||=`.

## `do`

`do effect; body` evaluates an expression, ignores its value, and continues.

```simpl
let r = ref 0;
do r += 1;
!r
```

## `=>` Probe

`=> expr; body` evaluates `expr`, prints it with `say`, binds the value to `it`,
and then evaluates `body`.

```simpl
=> 1 + 2;
it + 3
```

This is useful when exploring programs from the CLI without rewriting the next
expression by hand.

## `guard`

`guard` is a single-branch early-return style expression.

```simpl
guard ready;
"ok"
```

Without `else`, a failed guard returns `nil`:

```simpl
guard false;
42 -- nil
```

With `else`, a failed guard returns the fallback:

```simpl
guard value is #Some(x) else 0;
x
```

The condition can include ordinary truthiness checks, `is` patterns, and nested
`and` refinement.

```simpl
guard xs is [x; ..rest] and x > 0 else 0;
x
```

`guard` does not open a multi-branch `| ... then ...` split. Use `if` for that.

## `if`

Single-route conditionals must close with `else` or `end`.

```simpl
if x > 0 then x else ~x
```

```simpl
if ready then "ok" end
```

`end` is shorthand for `else nil`.

Multi-route conditionals start with leading `|` arms:

```simpl
if
| n < 0 then "negative"
| n == 0 then "zero"
else "positive"
```

Conditions use Simpl truthiness. They do not have to evaluate to booleans.

## `if ... is`

Pattern-directed branching uses `is`, not a separate `match` keyword.

```simpl
if result is
| #Ok(value) then value
| #Err(message) then message
else nil
```

An `is` condition can also appear as the head of a single route:

```simpl
if #Left(41) is #Left(x) then x + 1 | true then 0 else -1
```

For readability, prefer the multi-route layout when matching variants or lists.

## Refinement With `and`

`and` opens a nested refinement after the outer condition or pattern has
succeeded.

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

Inside this conditional syntax, `and` is structural refinement. For ordinary
boolean operators in expressions, use `&&` and `||`.

## Closing Nested Splits With `or`

Inside `if` refinement syntax, `or` closes the current nested split and returns
to the enclosing split.

```simpl
if
| true and
  | false then 1
  | true then 2
  or
| true then 3
else 0
```

For boolean OR, use `||`.

## Pattern Forms

Supported patterns:

- variable binder: `x`
- wildcard: `_`
- literals: `1`, `true`, `"ok"`, `nil`
- variants: `#Some(x)`
- records: `{x; y = renamed}`
- lists: `[head; second]`
- list rest: `[head; ..tail]`, `[first; ..middle; last]`
- alternatives: `#Some(x) | #Ok(x)`
- as-patterns: `#Ok(x) as whole`

Examples:

```simpl
let [head; ..tail] = [1; 2; 3];
let {name; score = points} = player;
let #Ok(x) as whole = #Ok(1);
```

Duplicate names in one pattern are rejected during evaluation.

Continue with [04 - Data and Mutation](./04-data-and-mutation.md).
