# Simpl `=`, `:=`, and `...=` Syntax

This document is the canonical reference for the `=` family in Simpl.

## 1. Operator Map

Simpl distinguishes **binding**, **comparison**, and **mutation**:

- `=`: binding/specification syntax (not a general expression operator)
- `==`: equality comparison expression
- `:=`: reference assignment expression
- `+=`, `-=`, `*=`, `/=`, `%=`, `&&=`, `||=`: reference update expressions

## 2. `=` (Binding and Specification)

`=` is used only in specific grammar forms.

## 2.1 `let` binding

```simpl
let x = 1; x + 1
let [a; b] = [10; 32]; a + b
let {x = left; y = right} = {x = 10; y = 32}; left + right
```

## 2.2 Function definition

```simpl
let add(x; y) = x + y; add(1; 2)
let add = fn(x; y) = x + y; add(1; 2)
fn(x) = x + 1
```

`let rec` definitions also use `=`:

```simpl
let rec even(n) = if n == 0 then true else odd(n - 1)
and odd(n) = if n == 0 then false else even(n - 1);
even(10)
```

## 2.3 Default parameter values

```simpl
fn(a; b = 2; c = 3) = a + b + c
```

## 2.4 Named call arguments

```simpl
f(a = 1; c = 3)
f(a = 1; 2; c = 3)
```

Named-lambda sugar in argument position:

```simpl
apply(f(x) = x + 1)
```

## 2.5 Record literals and record patterns

Record literal fields:

```simpl
{x = 1; y = 2}
{x; y = 2}
{inc(x) = x + 1}
```

Record pattern field mapping:

```simpl
let {x = left; y = right} = {x = 10; y = 32}; left + right
```

## 3. `==` (Equality)

`==` is the equality operator in expressions.

```simpl
if x == 1 then 2 else 3
[1; 2] == [1; 2]
```

Use `==`, not `=` for comparison.

## 4. `:=` (Reference Assignment)

`:=` mutates a reference cell.

```simpl
let r = ref(1);
r := 3
```

`:=` is an expression and returns the assigned value.

```simpl
let r = ref(1);
let x = r := 3;
!r + x   // 6
```

## 5. `...=` Reference Update Operators

Simpl supports these update operators:

- `+=`
- `-=`
- `*=`
- `/=`
- `%=`
- `&&=`
- `||=`

They are expression forms for references:

```simpl
let r = ref(10);
do r -= 3;
do r *= 4;
do r /= 2;
do r %= 5;
!r
```

Logical updates short-circuit according to `&&` / `||` behavior.

```simpl
let r = ref(false);
let t = ref(0);
do r &&= (do t := 1; true);
!t   // 0
```

## 6. `let` Compound Binding Sugar vs Reference Update

Inside `let`, `x += y` is **not** reference mutation.
It is sugar for rebinding `x`:

```simpl
let x = 1;
let x += 41;
x
```

Equivalent to:

```simpl
let x = 1;
let x = x + 41;
x
```

The same applies to:

- `let x -= ...`
- `let x *= ...`
- `let x /= ...`
- `let x %= ...`
- `let x &&= ...`
- `let x ||= ...`

## 7. Precedence and Associativity Notes

Assignment-style operators (`:=`, `+=`, etc.) parse in the assignment layer and associate to the right.
So chained forms group from right to left.

Example shape:

```simpl
a := b := 1
```

parses like:

```simpl
a := (b := 1)
```

(At runtime, validity still depends on whether the left sides are valid references.)

## 8. Common Mistakes

Using `=` for comparison:

```simpl
if x = 1 then 2 else 3   // invalid
```

Using `=` for mutation:

```simpl
r = 3   // invalid
```

Correct forms:

```simpl
if x == 1 then 2 else 3
r := 3
```

## 9. Summary

- `=` defines/binds/specifies in syntax forms.
- `==` compares values.
- `:=` mutates references.
- `...=` updates references (or rebinds when used as `let` compound sugar).
