# Composing `int(func)`, `list(func)`, and `with`

This guide describes how to combine `with`, `int(func)`, and `list(func)` in current Simpl.

## 1. `with` Is Call Sugar

`with` appends a lambda as the trailing argument of a target expression.

- `with(params) = target; body` => `target(fn(params) = body)`
- `with x = target; body` => `target(fn(x) = body)`
- `with target; body` => `target(fn() = body)`

In everyday reading, `with x = expr; ...` feels like introducing a name in the following expression, but operationally it is still call sugar.

## 2. `int(func)` and `list(func)` Semantics

## 2.1 `int(func)`

For `n(func)` when `func` is a function:

- `func` is called **without arguments**
- called `n` times
- return values are collected into a list
- if one call returns a list, it is flattened one level into the final collection
- if one call returns `nil`, it contributes nothing (treated as empty)

Also:

- `n(str)` means string repetition
- `n(list)` means list repetition

## 2.2 `list(func)`

For `xs(func)` when `func` is a function:

- `func` is called once for each element, with that element as the single argument
- results are collected
- returned lists are flattened one level
- returned `nil` contributes nothing

Important: Simpl no longer routes by checking function parameter count first. Calls are attempted directly; normal arity errors come from the function call itself.

## 3. Practical Examples

## 3.1 Two `with` bindings + string interpolation style

```simpl
with msg = ["Hi"; "Bye"];
with name = ["Alice"; "Bob"; "Mary"];
say msg", "name"!"
```

Expanded shape:

```simpl
["Hi"; "Bye"](fn(msg) =
  ["Alice"; "Bob"; "Mary"](fn(name) =
    say msg", "name"!"
  )
)
```

Output:

```text
Hi, Alice!
Hi, Bob!
Hi, Mary!
Bye, Alice!
Bye, Bob!
Bye, Mary!
=>
```

## 3.2 Repeating side effects

```simpl
with 3;
say "hello"
```

Expanded shape:

```simpl
3(fn() = say "hello")
```

Output:

```text
hello
hello
hello
=>
```

## 3.3 Chained interpolation with list-driven `with`

```simpl
with i = [0; 1];
with j = [0; 1; 2];
$i"+"$j"="$(i + j)
```

Expanded shape:

```simpl
[0; 1](fn(i) =
  [0; 1; 2](fn(j) =
    $i"+"$j"="$(i + j)
  )
)
```

Output:

```text
=> ["0+0=0"; "0+1=1"; "0+2=2"; "1+0=1"; "1+1=2"; "1+2=3"]
```

## 3.4 Flattening and `nil` behavior

```simpl
3(fn() = [1; 2])
// => [1; 2; 1; 2; 1; 2]

3(fn() = nil)
// => []

[1; 2; 3](fn(x) = [x; x * 10])
// => [1; 10; 2; 20; 3; 30]

[1; 2; 3](fn(x) = if x % 2 == 0 then x end)
// => [2]
```

## 4. Mental Model

- `with` builds and passes a trailing lambda.
- `int(func)` is repeat-and-collect (zero-arg calls).
- `list(func)` is map/flatMap-like collect over elements.
- one-level list flattening + `nil` as empty contribution make compositions concise.
