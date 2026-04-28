# Composing `int(func)`, `list(func)`, and `with` in Simpl

This guide shows how to combine `with`, `int(func)`, and `list(func)` in everyday Simpl code.

## 1. `with` at a Glance

`with` is call sugar.

- `with(params) = target; body` => `target(fn(params) = body)`
- `with x = target; body` => `target(fn(x) = body)`
- `with target; body` => `target(fn() = body)`

In practice, `with i = 2;` can be read as introducing the name `i` for the following expression.

## 2. Examples

## 2.1 Cross combinations with two `with` bindings

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

## 2.2 Repeating side effects with `with target; body`

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

## 2.3 Chained values + interpolation

```simpl
with i = 2;
with j = 3;
$i"+"$j"="$(i + j)
```

Expanded shape:

```simpl
2(fn(i) =
  3(fn(j) =
    $i"+"$j"="$(i + j)
  )
)
```

Output:

```text
=> ["0+0=0"; "0+1=1"; "0+2=2"; "1+0=1"; "1+1=2"; "1+2=3"]
```

## 3. Composition Rules (Current Runtime)

## 3.1 `int(func)`

- 1 parameter: called with `0..n-1`
- 0 parameters: called `n` times
- results are collected
- returned lists are flattened one level
- returned `nil` is treated as empty contribution

## 3.2 `list(func)`

- function must have exactly 1 parameter
- called once per element
- results are collected
- returned lists are flattened one level
- returned `nil` is treated as empty contribution

## 4. Mental Model

- `with ...` builds a lambda and passes it into a target call.
- `int(func)` is index-driven collection/execution.
- `list(func)` is element-driven collection/execution.
- list-return and `nil`-return behavior make both forms work like expression-level `flatMap`.
