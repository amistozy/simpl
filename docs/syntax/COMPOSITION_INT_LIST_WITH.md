# Composing `int(func)`, `list(func)`, and `with` in Simpl

This guide shows how three features combine into a compact mini-pipeline style:

- `n(func)` for repeated function execution (with index support)
- `list(func)` for element-wise function application
- `with ...; ...` for attaching a trailing lambda to a target call

Together, they let you write expressive code without adding new control-flow syntax.

## 1. Quick Semantics Recap

## 1.1 `int(func)`

For `n(func)`:

- if `func` has 1 parameter: call with `0..n-1`
- if `func` has 0 parameters: call `n` times
- results are collected into a list
- if one call returns a list, that list is flattened one level into the collected output
- if one call returns `nil`, it is treated as an empty list contribution (ignored)

## 1.2 `list(func)`

For `xs(func)`:

- `func` must have exactly 1 parameter
- call `func` for each element of `xs`
- collect results into a list
- list results are flattened one level
- `nil` results are ignored

## 1.3 `with`

`with` appends a lambda as the trailing argument of a target expression:

```simpl
with(v) = target; body
```

is equivalent to:

```simpl
target(fn(v) = body)
```

Also:

```simpl
with target; body
```

is equivalent to:

```simpl
target(fn() = body)
```

## 2. Useful Composition Patterns

## 2.1 Build indexed data in one expression

```simpl
10(fn(i) = {i; square = i * i})
```

Result shape: list of records from `i = 0` to `9`.

## 2.2 Nested generation + flattening

```simpl
3(fn(i) = [i; i + 10])
// => [0; 10; 1; 11; 2; 12]
```

Because call results are flattened one level, this acts like `flatMap`.

## 2.3 Filter-like behavior with `nil`

```simpl
10(fn(i) = if i % 2 == 0 i else nil end)
// => [0; 2; 4; 6; 8]
```

Returning `nil` removes the item from output collection.

## 2.4 Map over list with expansion

```simpl
[1; 2; 3](fn(x) = [x; x * 100])
// => [1; 100; 2; 200; 3; 300]
```

## 2.5 Compose generator then transformer

```simpl
with(seed) = 5(fn(i) = i + 1);
seed(fn(x) = x * x)
// => [1; 4; 9; 16; 25]
```

First produce `[1; 2; 3; 4; 5]`, then map square.

## 2.6 Local pipeline style with `with`

```simpl
with(xs) = 8(fn(i) = if i % 2 == 0 i else nil end);
xs(fn(x) = {value = x; doubled = x * 2})
```

This keeps intermediate values scoped and readable.

## 3. Practical Tips

- Use `int(func)` when you need a numeric range without naming a loop.
- Use `list(func)` when transforming existing collections.
- Return `nil` to drop items during collection.
- Return `[a; b; ...]` to expand one input into multiple outputs.
- Use `with` when a temporary name makes multi-step expressions clearer.

## 4. Mental Model

You can treat both call forms as collection builders:

- `int(func)` is index-driven collection
- `list(func)` is data-driven collection

Both support:

- one-level flattening
- `nil`-as-empty contribution

That makes them feel like compact, expression-oriented `flatMap` primitives.

## 5. Caveats

- `int(func)` accepts only 0-arg or 1-arg functions.
- `list(func)` accepts only 1-arg functions.
- flattening is one level only (nested lists inside returned lists are not recursively flattened).
