# 05. Callable Composition

Simpl's most distinctive feature is that several data values are callable. This
lets small programs read as chains of value composition instead of requiring a
separate operator for every data shape.

## Callable Strings

A string called with one positional argument can concatenate another string:

```simpl
"hello " "world"
```

It can also join a list using itself as the separator:

```simpl
", "([1; 2; 3])
```

String elements are joined as raw text. Other values use their pretty display
form.

```simpl
","(["a"; "b"; 1]) -- "a,b,1"
```

## Interpolation By Calling

Simpl does not have template literals. Interpolation is just string calls plus
`$`.

```simpl
let name = "Alice";
let age = 18;
"Hello, "name". You are "$age"."
```

Because calls can be adjacent, interpolation chains naturally from either a
literal or a variable.

## Callable Integers

An integer called with one positional argument can repeat a string:

```simpl
3("ha")
```

It can repeat a list:

```simpl
3([1; 2])
```

It can call a zero-argument function repeatedly and collect the results:

```simpl
3(fn() 5)
```

Function repetition has collection semantics:

- `nil` results are skipped
- returned lists are flattened by one level
- ordinary values are appended

```simpl
3(fn() [1; 2]) -- [1; 2; 1; 2; 1; 2]
3(fn() nil)    -- []
```

Multiplication shares the same repetition behavior:

```simpl
3 * "ha"
"ha" * 3
3 * [1; 2]
(fn() 5) * 3
```

Non-positive repetition counts produce an empty string or list.

## Callable Lists

A list called with one positional argument can join with a string separator:

```simpl
[1; 2; 3](", ")
```

It can index by integer:

```simpl
[10; 20; 30](0)
[10; 20; 30](-1)
```

Negative indices count from the end. Out-of-range indices return `nil`.

It can batch-index by a list of integers:

```simpl
[10; 20; 30]([0; -1; 9]) -- [10; 30; nil]
```

It can map or collect with a function:

```simpl
[1; 2; 3](fn(x) x * 2)
[1; 2](fn(x) [x; x + 10])
[1; 2](fn(_) nil)
```

List function calls use the same collection rule as integer function
repetition: skip `nil`, flatten returned lists by one level, append ordinary
values.

This differs from the `map` built-in, which preserves one output per input.

```simpl
map([1; 2]; fn(x) [x; x + 10]) -- [[1; 11]; [2; 12]]
[1; 2](fn(x) [x; x + 10])      -- [1; 11; 2; 12]
```

## Callable Records

A record called with named arguments returns an updated copy.

```simpl
let point = {x = 1; y = 2};
point(x = 3; z = 4)
```

This is useful for small immutable updates. It does not mutate `point`.

## UFCS Composition

UFCS-style fallback makes built-ins and user functions read like methods:

```simpl
[1; 2; 3].map(fn _ * 2)
[1; 2; 3].filter(fn _ > 1)
[1; 2; 3].fold(0; fn _ + _)
```

The field name is resolved as a record field first. If that fails, Simpl looks
for a function with the same name and passes the receiver as its first argument.

## `with` As Repetition

`with` pairs naturally with callable integers:

```simpl
with 3;
say "hello"
```

This means:

```simpl
3(fn() say "hello")
```

Since `say` returns `nil`, the collected result is `[]`, and the useful effect
is the printed output.

Continue with [06 - CLI and Embedding](./06-cli-and-embedding.md).
