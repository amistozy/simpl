# Composing `int(func)`, `list(func)`, and `with` in Simpl

This note explains the real composition model behind `with`, `int(func)`, and `list(func)`.

## 1. Core Truth About `with`

`with` is a call sugar.

- `with(params) = target; body` => `target(fn(params) = body)`
- `with x = target; body` => `target(fn(x) = body)`
- `with target; body` => `target(fn() = body)`

So `with` always appends a lambda as a trailing argument to a target expression.

## 2. Why Your Examples Are Interesting

## 2.1 Example A

```simpl
with msg = ["Hi"; "Bye"];
with name = ["Alice"; "Bob"; "Mary"];
say msg", "name"!"
```

This is not two nested `let`s.

It is equivalent in shape to:

```simpl
["Hi"; "Bye"](fn(msg) =
  ["Alice"; "Bob"; "Mary"](fn(name) =
    say msg", "name"!"
  )
)
```

Because list call applies the function to each element and collects results, this becomes a compact cross-combination style pattern.

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

## 2.2 Example B

```simpl
with 3;
say "hello"
```

Equivalent shape:

```simpl
3(fn() = say "hello")
```

Since `int(func)` with a zero-arg function runs it `n` times, this executes `say "hello"` three times.

Output:

```text
hello
hello
hello
=>
```

## 2.3 Example C (chained `with` + interpolation)

```simpl
with i = 2;
with j = 3;
$i"+"$j"="$(i + j)
```

Equivalent shape:

```simpl
2(fn(i) =
  3(fn(j) =
    $i"+"$j"="$(i + j)
  )
)
```

This demonstrates that `with` can pass values through nested lambdas, while string-call chaining keeps expression-style interpolation concise.

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
