# Composition Patterns

Simpl becomes much easier to read once you treat calls as a general composition
mechanism rather than as function-only syntax.

## Callable Strings

A string called with one positional argument does one of two things:

- concatenate another string
- join a list using itself as the separator

Examples:

```simpl
"hello " "world"
", "([1; 2; 3])
```

This is the basis of Simpl string interpolation.

## String Interpolation

Interpolation is expression-based. It uses:

- string calls
- trailing application
- `$` for text conversion

Example:

```simpl
let name = "Alice";
let age = 18;
name" is "$age" years old"
```

Grouped forms such as `$(...)`, `$[...]`, and `${...}` are useful when the next
expression is not a simple atom.

## Callable Integers

An integer called with one positional argument can:

- repeat a string
- repeat a list
- call a function repeatedly and collect results

Examples:

```simpl
3("ha")
3([1; 2])
3(fn() 5)
```

When repeatedly calling a function:

- `nil` contributes nothing
- returned lists are flattened by one level
- ordinary values are appended

## Callable Lists

A list called with one positional argument can:

- join using a string separator
- index by `Int`
- batch-index by `List[Int]`
- map/collect with a function

Examples:

```simpl
[10; 20; 30](", ")
[10; 20; 30](1)
[10; 20; 30]([0; -1; 9])
[1; 2; 3](fn(x) x * 2)
[1; 2; 3](_ * 2)
```

Negative indices count from the end. Out-of-range indices return `nil`.

When a list maps with a function, returned lists are flattened by one level and
returned `nil` values are skipped.

Because `fn expr` eta-expansion works anywhere an expression is allowed, list
mapping and the collection built-ins stay concise:

```simpl
map([1; 2; 3]; fn _ * 2)
filter([1; nil; 2]; fn _ != nil)
fold([1; 2; 3]; 0; fn _ + _)
```

When a `fn expr` body needs a larger infix shape, `:()` can make that boundary
explicit:

```simpl
[1; 20; 3]
.map(fn: (_ + 1) * 2)
.filter(fn _ < 10)
```

## Callable Records

A record can be called with named arguments to produce an updated record:

```simpl
let point = {x = 1; y = 2};
point(x = 3; z = 4)
```

This does not mutate the original record.

## `with` as Composition Sugar

`with` passes a trailing lambda:

```simpl
with(x) = [1; 2; 3]; x + 1
```

This is equivalent to:

```simpl
[1; 2; 3](fn(x) x + 1)
```

It also works well with callable integers:

```simpl
with 3; say "hello"
```

which means:

```simpl
3(fn() say "hello")
```

## Practical Reading Rule

When you see `value(arg)` in Simpl, do not assume `value` is a function.

Instead, ask:

1. is it a function or built-in?
2. is it a string being used to concatenate or join?
3. is it a list being used to index or map?
4. is it an integer being used to repeat or collect?
5. is it a record being updated through named arguments?

That single shift in perspective makes much of the language feel coherent.
