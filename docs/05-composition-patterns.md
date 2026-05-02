# 05. Composition Patterns

This is the most distinctive part of Simpl. Many values are callable, so the
language often reads like "compose values by calling them" rather than "apply a
special syntax rule for each data type".

## Callable strings

A string called with one positional argument can:

- concatenate another string
- join a list using itself as the separator

Examples:

```simpl
"hello " "world"
", "([1; 2; 3])
```

## String interpolation

Simpl does not use template literals. Instead, interpolation is expression
based and relies on:

- string calls
- trailing application
- `$` for text conversion

```simpl
let name = "Alice";
let age = 18;
name" is "$age" years old"
```

Grouped forms such as `$(...)`, `$[...]`, and `${...}` help when the next
expression is not a simple atom.

## Callable integers

An integer called with one positional argument can:

- repeat a string
- repeat a list
- call a function repeatedly and collect the results

Examples:

```simpl
3("ha")
3([1; 2])
3(fn() 5)
```

When the integer repeatedly calls a function:

- `nil` results are skipped
- returned lists are flattened by one level
- ordinary values are appended

## Callable lists

A list called with one positional argument can:

- join using a string separator
- index by `Int`
- batch-index by `List[Int]`
- map or collect with a function

Examples:

```simpl
[10; 20; 30](", ")
[10; 20; 30](1)
[10; 20; 30]([0; -1; 9])
[1; 2; 3](fn(x) x * 2)
[1; 2; 3](_ * 2)
```

Notes:

- negative indices count from the end
- out-of-range indices return `nil`
- function mapping also skips `nil` and flattens returned lists by one level

## Callable records

A record can be called with named arguments to produce an updated record:

```simpl
let point = {x = 1; y = 2};
point(x = 3; z = 4)
```

This creates a new record. It does not mutate the original one.

## Built-in functions

The current built-ins are:

- `ref(value)`
- `say(value)`
- `map(list; f)`
- `filter(list; f)`
- `fold(list; init; f)`
- `length(value)`
- `max(a; b)` or `max(list)`
- `min(a; b)` or `min(list)`
- `sum(list)`

Built-ins do not accept named arguments.

## Composition examples

```simpl
map([1; 2; 3]; fn _ * 2)
filter([1; nil; 2]; fn _ != nil)
fold([1; 2; 3]; 0; fn _ + _)
```

```simpl
with 3; say "hello"
```

This means:

```simpl
3(fn() say "hello")
```

## Reading rule

When you see `value(arg)` in Simpl, do not assume `value` is a function.

Ask instead:

1. is it a function or built-in?
2. is it a string being used to concatenate or join?
3. is it a list being used to index, join, or map?
4. is it an integer being used to repeat or collect?
5. is it a record being updated through named arguments?

Once that model clicks, a lot of Simpl becomes much easier to read.
