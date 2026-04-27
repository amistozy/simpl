///|
/// Blackbox: basic arithmetic and dynamic type checks
test "int arithmetic" {
  assert_true(@simpl.eval_source_is_int("1 + 2", 3))
}

///|
test "string concatenation" {
  assert_true(
    @simpl.eval_source_is_string("\"hello \" + \"moonbit\"", "hello moonbit"),
  )
}

///|
test "string literals support common escape sequences" {
  let code =
    #| "line1\nline2\t\"quote\"\\slash\rend"
  assert_true(
    @simpl.eval_source_is_string(code, "line1\nline2\t\"quote\"\\slash\rend"),
  )
}

///|
test "type error remains runtime error" {
  assert_true(@simpl.eval_source_is_error("1 + true"))
}

///|
test "single-line comment supports full-line comment" {
  let code =
    #| -- this is a comment
    #| 1 + 2
  assert_true(@simpl.eval_source_is_int(code, 3))
}

///|
test "single-line comment supports end-of-line comment" {
  let code =
    #| let x = 1; -- keep x small
    #| x + 2
  assert_true(@simpl.eval_source_is_int(code, 3))
}

///|
test "single-line comment can appear between expressions" {
  let code =
    #| let x = 1;
    #| -- middle comment
    #| let y = 2;
    #| x + y
  assert_true(@simpl.eval_source_is_int(code, 3))
}

///|
test "comparison and logic operators" {
  assert_true(@simpl.eval_source_is_bool("1 < 2 && 3 == 3", true))
  assert_true(@simpl.eval_source_is_bool("4 > 1 || false", true))
}

///|
/// Blackbox: functional closures with lexical environment
test "closure captures lexical env" {
  let code =
    #| let x = 10;
    #| let f(y) = x + y;
    #| let x = 100;
    #| f(5)
  assert_true(@simpl.eval_source_is_int(code, 15))
}

///|
test "higher order function" {
  let code =
    #| (fn(f) = f(41))(fn(x) = x + 1)
  assert_true(@simpl.eval_source_is_int(code, 42))
}

///|
test "single-parameter lambda can omit parentheses" {
  let code =
    #| (fn x = x + 1)(41)
  assert_true(@simpl.eval_source_is_int(code, 42))
}

///|
test "trailing arg sugar rewrites f x to f(x)" {
  let code =
    #| let inc(x) = x + 1;
    #| inc 41
  assert_true(@simpl.eval_source_is_int(code, 42))
}

///|
test "trailing arg sugar appends to existing arg list" {
  let code =
    #| let add3(a; b; c) = a + b + c;
    #| add3(1; 2) 3
  assert_true(@simpl.eval_source_is_int(code, 6))
}

///|
test "trailing arg has lowest precedence over infix operators" {
  let code =
    #| let f(x) = x + 1;
    #| f 1 * 2
  assert_true(@simpl.eval_source_is_int(code, 3))
}

///|
test "trailing lambda works with lowest precedence application" {
  let code =
    #| let foo(f) = f 42;
    #| foo fn(x) = x + 1
  assert_true(@simpl.eval_source_is_int(code, 43))
}

///|
test "with(params) sugar appends lambda as last argument" {
  let code =
    #| let use(x; f) = f(x);
    #| with(v) = use(41); v + 1
  assert_true(@simpl.eval_source_is_int(code, 42))
}

///|
test "with x = ... sugar supports single param without parentheses" {
  let code =
    #| let use(x; f) = f(x);
    #| with v = use(41); v + 1
  assert_true(@simpl.eval_source_is_int(code, 42))
}

///|
test "with foo(...); ... sugar supports zero-parameter lambda" {
  let code =
    #| let run(f) = f();
    #| with run(); 42
  assert_true(@simpl.eval_source_is_int(code, 42))
}

///|
test "trailing application is right-associative" {
  let code =
    #| let f(v) = v * 10;
    #| let g(x) = x + 2;
    #| let x = 3;
    #| f g x
  assert_true(@simpl.eval_source_is_int(code, 50))
}

///|
test "named arg supports f(...) = ... sugar" {
  let code =
    #| let apply(f) = f(41);
    #| apply(f(x) = x + 1)
  assert_true(@simpl.eval_source_is_int(code, 42))
}

///|
test "named arg supports single-param f x = ... sugar" {
  let code =
    #| let apply(f) = f(41);
    #| apply(f x = x + 1)
  assert_true(@simpl.eval_source_is_int(code, 42))
}

///|
test "record field supports f(...) = ... sugar" {
  let code =
    #| let r = {inc(x) = x + 1};
    #| r.inc(41)
  assert_true(@simpl.eval_source_is_int(code, 42))
}

///|
test "record field supports single-param f x = ... sugar" {
  let code =
    #| let r = {inc x = x + 1};
    #| r.inc(41)
  assert_true(@simpl.eval_source_is_int(code, 42))
}

///|
test "ufcs rewrites x.foo to foo(x) when no record field exists" {
  let code =
    #| let inc(x) = x + 1;
    #| 41.inc
  assert_true(@simpl.eval_source_is_int(code, 42))
}

///|
test "ufcs rewrites x.foo(y; z) to foo(x; y; z)" {
  let code =
    #| let add3(x; y; z) = x + y + z;
    #| 1.add3(2; 3)
  assert_true(@simpl.eval_source_is_int(code, 6))
}

///|
test "record field lookup has priority over ufcs fallback" {
  let code =
    #| let foo(x) = x + 100;
    #| let r = {foo(v) = v + 1};
    #| r.foo(41)
  assert_true(@simpl.eval_source_is_int(code, 42))
}

///|
test "record is callable with named args to create updated record" {
  let code =
    #| let foo = {x = 1; y = 2};
    #| let bar = foo(x = 3; z = 4);
    #| bar.x + bar.y + bar.z
  assert_true(@simpl.eval_source_is_int(code, 9))
}

///|
test "record call does not mutate original record" {
  let code =
    #| let foo = {x = 1; y = 2};
    #| let _ = foo(x = 3; z = 4);
    #| foo.x + foo.y
  assert_true(@simpl.eval_source_is_int(code, 3))
}

///|
test "record call rejects positional arguments" {
  let code =
    #| let foo = {x = 1};
    #| foo(1)
  assert_true(@simpl.eval_source_is_error(code))
}

///|
test "string is callable: string arg means concatenation" {
  assert_true(
    @simpl.eval_source_is_string("\"hello \"(\"world\")", "hello world"),
  )
}

///|
test "string is callable: list arg means join with separator" {
  assert_true(@simpl.eval_source_is_string("\", \"([1; 2; 3])", "1, 2, 3"))
}

///|
test "string join on list uses raw text for string elements" {
  assert_true(@simpl.eval_source_is_string("\",\"([\"a\"; \"b\"; 1])", "a,b,1"))
}

///|
test "string call rejects unsupported argument type" {
  assert_true(@simpl.eval_source_is_error("\"x\"(1)"))
}

///|
test "function params without defaults are required" {
  let code =
    #| (fn(x; y) = x)()
  assert_true(@simpl.eval_source_is_error(code))
}

///|
test "function supports explicit default values" {
  let code =
    #| let f(y; x = 1; z = 3) = x + y + z;
    #| f(y = 2)
  assert_true(@simpl.eval_source_is_int(code, 6))
}

///|
test "named args are matched before positional args" {
  let code =
    #| let f(a; b; c) = a + b + c;
    #| f(a = 1; 2; c = 3)
  assert_true(@simpl.eval_source_is_int(code, 6))
}

///|
test "default expressions cannot reference params" {
  let code =
    #| let f(a = 1; b = a + 1) = b;
    #| f()
  assert_true(@simpl.eval_source_is_error(code))
}

///|
test "param default lambda sugar f(x)=... works as f = fn(x)=..." {
  let code =
    #| let foo(f(x) = x) = f(42);
    #| foo()
  assert_true(@simpl.eval_source_is_int(code, 42))
}

///|
test "param default lambda sugar supports single-param f x = ..." {
  let code =
    #| let foo(f x = x) = f(42);
    #| foo()
  assert_true(@simpl.eval_source_is_int(code, 42))
}

///|
test "default expressions are evaluated at definition time" {
  let code =
    #| let r = ref(1);
    #| let f(x = !r) = x;
    #| do r := 2;
    #| f()
  assert_true(@simpl.eval_source_is_int(code, 1))
}

///|
test "params must place required ones before defaulted ones" {
  assert_true(@simpl.parse_is_error("fn(x = 1; y) = x + y"))
}

///|
/// Blackbox: parser + evaluator
test "eval_source honors operator precedence" {
  assert_true(@simpl.eval_source_is_int("1 + 2 * 3", 7))
}

///|
test "parse error is reported" {
  assert_true(@simpl.eval_source_is_error("let x = 1 x + 2"))
  assert_true(@simpl.parse_is_error("let x = 1 x + 2"))
}

///|
test "legacy match syntax is rejected" {
  assert_true(@simpl.parse_is_error("match 42 with | 42 -> 1"))
}

///|
test "or is reserved for UCS and not a boolean operator" {
  assert_true(@simpl.parse_is_error("true or false"))
}

///|
test "is expression is removed" {
  assert_true(@simpl.parse_is_error("x is #Some(y)"))
}

///|
test "parse error includes source position" {
  assert_eq(
    @simpl.parse_error_text("1 )"),
    Some("unexpected token after expression: ) at 1:3-4"),
  )
}

///|
test "invalid string escape reports source position" {
  assert_eq(
    @simpl.parse_error_text("\"a\\q\""),
    Some("invalid escape sequence: \\q at 1:3-5"),
  )
}

///|
test "unterminated string escape reports source position" {
  assert_eq(
    @simpl.parse_error_text("\"a\\"),
    Some("unterminated escape sequence in string literal at 1:3-4"),
  )
}

///|
test "ref basics and assignment expression value" {
  let code =
    #| let r = ref(1);
    #| let x = r := 3;
    #| !r + x
  assert_true(@simpl.eval_source_is_int(code, 6))
}

///|
test "print is available as builtin and returns nil" {
  let code =
    #| do print(1);
    #| 42
  assert_true(@simpl.eval_source_is_int(code, 42))
}

///|
test "say outputs string and returns nil" {
  let code =
    #| do say("hello");
    #| 42
  assert_true(@simpl.eval_source_is_int(code, 42))
}

///|
test "say only accepts string" {
  assert_eq(
    @simpl.eval_error_text("say(1)"),
    Some("builtin 'say' expected String, got Int(1) at 1:1-7"),
  )
}

///|
test "map applies function to each list element" {
  let code =
    #| map([1; 2; 3]; fn(x) = x + 1) == [2; 3; 4]
  assert_true(@simpl.eval_source_is_bool(code, true))
}

///|
test "map accepts any callable value as second argument" {
  let code =
    #| ["a"; "b"].map("c") == ["ca"; "cb"]
  assert_true(@simpl.eval_source_is_bool(code, true))
}

///|
test "map validates argument types" {
  assert_eq(
    @simpl.eval_error_text("map(1; fn(x) = x)"),
    Some("builtin 'map' expected List, got Int(1) at 1:1-18"),
  )
  assert_eq(
    @simpl.eval_error_text("map([1]; 1)"),
    Some("builtin 'map' expected Callable, got Int(1) at 1:1-12"),
  )
}

///|
test "print does not accept named arguments" {
  assert_true(@simpl.eval_source_is_error("print(x = 1)"))
}

///|
test "string interpolation uses call chaining without spaces" {
  let code =
    #| let name = "Alice";
    #| let age = 18;
    #| name" is "$age" years old"
  assert_true(@simpl.eval_source_is_string(code, "Alice is 18 years old"))
}

///|
test "string interpolation chaining supports multiple typed values" {
  let code =
    #| let name = "Bob";
    #| let age = 20;
    #| let score = 99;
    #| name" age="$age", score="$score
  assert_true(@simpl.eval_source_is_string(code, "Bob age=20, score=99"))
}

///|
test "dollar supports $(...), $[...], ${...} forms" {
  let code =
    #| let x = 1;
    #| let y = 2;
    #| "sum="$(x + y)", list="$[x; y]", record="${x; y}
  assert_true(
    @simpl.eval_source_is_string(
      code, "sum=3, list=[1; 2], record={x = 1; y = 2}",
    ),
  )
}

///|
test "string interpolation chaining can start from literal" {
  let code =
    #| let name = "Carol";
    #| "Hello, "name"!"
  assert_true(@simpl.eval_source_is_string(code, "Hello, Carol!"))
}

///|
test "division by zero now returns zero" {
  assert_true(@simpl.eval_source_is_int("1 / 0", 0))
}

///|
test "modulo by zero returns dividend" {
  assert_true(@simpl.eval_source_is_int("7 % 0", 7))
  assert_true(@simpl.eval_source_is_int("7 % 3", 1))
}

///|
test "string repetition supports both multiplication directions" {
  assert_true(@simpl.eval_source_is_string("3 * \"ha\"", "hahaha"))
  assert_true(@simpl.eval_source_is_string("\"ha\" * 3", "hahaha"))
}

///|
test "list repetition supports both multiplication directions" {
  assert_true(
    @simpl.eval_source_is_bool("[1; 2] * 3 == [1; 2; 1; 2; 1; 2]", true),
  )
  assert_true(
    @simpl.eval_source_is_bool("3 * [1; 2] == [1; 2; 1; 2; 1; 2]", true),
  )
}

///|
test "non-positive repetition count returns empty string or list" {
  assert_true(@simpl.eval_source_is_string("\"ha\" * 0", ""))
  assert_true(@simpl.eval_source_is_string("-2 * \"ha\"", ""))
  assert_true(@simpl.eval_source_is_bool("[1; 2] * 0 == []", true))
  assert_true(@simpl.eval_source_is_bool("[1; 2] * -1 == []", true))
}

///|
test "unary type error reports expected and actual value" {
  assert_eq(
    @simpl.eval_error_text("-true"),
    Some("type error: unary '-' expected Int, got Bool(true) at 1:1-6"),
  )
}

///|
test "binary type error reports expected and actual values" {
  assert_eq(
    @simpl.eval_error_text("1 + true"),
    Some(
      "type error: operator '+' expected (Int, Int) or (String, String), got (Int(1), Bool(true)) at 1:1-9",
    ),
  )
}

///|
test "field access falls back to ufcs and reports missing function" {
  assert_eq(
    @simpl.eval_error_text("1.x"),
    Some("undefined variable: name 'x' is not bound at 1:1-4"),
  )
}

///|
test "undefined variable reports missing binding name" {
  assert_eq(
    @simpl.eval_error_text("x"),
    Some("undefined variable: name 'x' is not bound at 1:1-2"),
  )
}

///|
test "missing field reports field name and record summary" {
  assert_eq(
    @simpl.eval_error_text("{x = 1}.y"),
    Some("missing field: record has no field 'y' in Record(1 fields) at 1:1-10"),
  )
}

///|
test "calling non-function reports actual value" {
  assert_eq(
    @simpl.eval_error_text("1(2)"),
    Some("call error: expected Function, got Int(1) at 1:1-5"),
  )
}

///|
test "arity error reports expected and actual argument counts" {
  assert_eq(
    @simpl.eval_error_text("let f(x) = x; f(1; 2)"),
    Some("arity error: expected 1 arguments, got 2 at 1:15-22"),
  )
}

///|
test "pattern match failure reports expected pattern and actual value" {
  assert_eq(
    @simpl.eval_error_text("let [x; y] = [1]; x"),
    Some("pattern match failure: expected [x; y], got [1] at 1:5-20"),
  )
}

///|
test "let function sugar equals lambda binding" {
  let code =
    #| let add2(x) = x + 2;
    #| add2(40)
  assert_true(@simpl.eval_source_is_int(code, 42))
}

///|
test "do sugar equals let _ = ...; ..." {
  let code =
    #| let r = ref(0);
    #| do r := 1;
    #| do r := !r + 41;
    #| !r
  assert_true(@simpl.eval_source_is_int(code, 42))
}

///|
test "do sugar nests like let _ bindings" {
  let code =
    #| let r = ref(0);
    #| do r := 1;
    #| do r := !r + 1;
    #| do r := !r + 1;
    #| !r
  assert_true(@simpl.eval_source_is_int(code, 3))
}

///|
test "and short-circuits right-hand side" {
  let code =
    #| let r = ref(0);
    #| do false && (r := 1 == 1);
    #| !r
  assert_true(@simpl.eval_source_is_int(code, 0))
}

///|
test "or short-circuits right-hand side" {
  let code =
    #| let r = ref(0);
    #| do true || (r := 1 == 1);
    #| !r
  assert_true(@simpl.eval_source_is_int(code, 0))
}

///|
test "ref += updates and returns new value" {
  let code =
    #| let r = ref(1);
    #| do r += 41;
    #| !r
  assert_true(@simpl.eval_source_is_int(code, 42))
}

///|
test "ref -=, *=, /=, %= chain correctly" {
  let code =
    #| let r = ref(10);
    #| do r -= 3;
    #| do r *= 4;
    #| do r /= 2;
    #| do r %= 5;
    #| !r
  assert_true(@simpl.eval_source_is_int(code, 4))
}

///|
test "ref &&= short-circuits right-hand side" {
  let code =
    #| let r = ref(false);
    #| let t = ref(0);
    #| do r &&= (do t := 1; true);
    #| !t
  assert_true(@simpl.eval_source_is_int(code, 0))
}

///|
test "ref ||= short-circuits right-hand side" {
  let code =
    #| let r = ref(true);
    #| let t = ref(0);
    #| do r ||= (do t := 1; false);
    #| !t
  assert_true(@simpl.eval_source_is_int(code, 0))
}

///|
test "and returns the actual operand value" {
  let code =
    #| "left" && "right"
  assert_true(@simpl.eval_source_is_string(code, "right"))
}

///|
test "or returns the actual operand value" {
  let code =
    #| nil || "fallback"
  assert_true(@simpl.eval_source_is_string(code, "fallback"))
}

///|
test "&& and || also return operand values" {
  let and_code =
    #| "left" && "right"
  let or_code =
    #| nil || "fallback"
  assert_true(@simpl.eval_source_is_string(and_code, "right"))
  assert_true(@simpl.eval_source_is_string(or_code, "fallback"))
}

///|
test "! works as logical not for non-reference values" {
  assert_true(@simpl.eval_source_is_bool("!false", true))
  assert_true(@simpl.eval_source_is_bool("!nil", true))
  assert_true(@simpl.eval_source_is_bool("!1", false))
}

///|
test "$ converts values to pretty string" {
  assert_true(@simpl.eval_source_is_string("$42", "42"))
  assert_true(@simpl.eval_source_is_string("$[1; 2]", "[1; 2]"))
  assert_true(@simpl.eval_source_is_string("$(#Some(1))", "#Some(1)"))
}

///|
test "$ works with refs after bang dereference" {
  let code =
    #| let r = ref(1);
    #| $(!r)
  assert_true(@simpl.eval_source_is_string(code, "1"))
}

///|
test "not is no longer a keyword" {
  assert_eq(
    @simpl.eval_error_text("not true"),
    Some("undefined variable: name 'not' is not bound at 1:1-4"),
  )
}

///|
test "record literal and field access" {
  let code =
    #| {name = "moon"; count = 2}.name
  assert_true(@simpl.eval_source_is_string(code, "moon"))
}

///|
test "record literal supports field shorthand" {
  let code =
    #| let x = 42; {x; y = 43}.x
  assert_true(@simpl.eval_source_is_int(code, 42))
}

///|
test "nested record fields" {
  let code =
    #| {user = {name = "moon"; active = true}}.user.name
  assert_true(@simpl.eval_source_is_string(code, "moon"))
}

///|
test "record field access can be used in expressions" {
  let code =
    #| let p = {x = 10; y = 32};
    #| p.x + p.y
  assert_true(@simpl.eval_source_is_int(code, 42))
}

///|
test "record destructuring binds fields" {
  let code =
    #| let {x; y} = {x = 10; y = 32};
    #| x + y
  assert_true(@simpl.eval_source_is_int(code, 42))
}

///|
test "record destructuring supports renaming" {
  let code =
    #| let {x = left; y = right} = {x = 10; y = 32};
    #| left + right
  assert_true(@simpl.eval_source_is_int(code, 42))
}

///|
test "let supports general patterns" {
  let code =
    #| let #Pair([x; y]) = #Pair([10; 32]);
    #| x + y
  assert_true(@simpl.eval_source_is_int(code, 42))
}

///|
test "list equality is recursive" {
  let code =
    #| [1; [2; 3]] == [1; [2; 3]]
  assert_true(@simpl.eval_source_is_bool(code, true))
}

///|
test "lambda parameters support patterns" {
  let code =
    #| (fn(#Pair(x); {y}) = x + y)(#Pair(10); {y = 32})
  assert_true(@simpl.eval_source_is_int(code, 42))
}

///|
test "let function sugar supports parameter patterns" {
  let code =
    #| let add_pair(#Pair(x); [y; z]) = x + y + z;
    #| add_pair(#Pair(10); [20; 12])
  assert_true(@simpl.eval_source_is_int(code, 42))
}

///|
test "let function sugar supports single param without parentheses" {
  let code =
    #| let inc x = x + 1;
    #| inc(41)
  assert_true(@simpl.eval_source_is_int(code, 42))
}

///|
test "let x += sugar equals let x = x + ...; ..." {
  let code =
    #| let x = 1;
    #| let x += 41;
    #| x
  assert_true(@simpl.eval_source_is_int(code, 42))
}

///|
test "let compound sugar supports -=, *=, /=, %=" {
  let code =
    #| let x = 10;
    #| let x -= 3;
    #| let x *= 4;
    #| let x /= 2;
    #| let x %= 5;
    #| x
  assert_true(@simpl.eval_source_is_int(code, 4))
}

///|
test "let compound sugar supports &&= and ||=" {
  let code =
    #| let x = true;
    #| let x &&= false;
    #| let x ||= true;
    #| x
  assert_true(@simpl.eval_source_is_bool(code, true))
}

///|
test "let and evaluates right-hand sides in outer environment" {
  let code =
    #| let x = 10;
    #| let x = 1 and y = x + 1;
    #| y
  assert_true(@simpl.eval_source_is_int(code, 11))
}

///|
test "let rec and supports mutual recursion" {
  let code =
    #| let rec even(n) = if n == 0 then true else odd(n - 1)
    #| and odd(n) = if n == 0 then false else even(n - 1);
    #| even(10)
  assert_true(@simpl.eval_source_is_bool(code, true))
}

///|
test "let rec and supports single-param shorthand" {
  let code =
    #| let rec even n = if n == 0 then true else odd(n - 1)
    #| and odd n = if n == 0 then false else even(n - 1);
    #| even(10)
  assert_true(@simpl.eval_source_is_bool(code, true))
}

///|
/// Blackbox: if syntax (current rules)
test "if requires closure in multi-route mode" {
  assert_true(@simpl.parse_is_error("if true then 1"))
}

///|
test "no-pipe single is first branch is treated as if multi-route" {
  assert_true(@simpl.parse_is_error("if #Some(1) is #Some(x) then x"))
}

///|
test "no-pipe multi-route is first branch enables if single-route mode" {
  let code =
    #| if #Some(1) is
    #| | #Some(x) then x
    #| | _ then 0
    #| end
  assert_true(@simpl.eval_source_is_int(code, 1))
}

///|
test "single-route if mode rejects hanging outer branches" {
  let code =
    #| if #Some(1) is
    #| | #Some(x) then x
    #| | _ then 0
    #| end
    #| | true then 2
    #| else 3
  assert_true(@simpl.parse_is_error(code))
}

///|
test "no-pipe single is can still hang follow-up if branches" {
  assert_true(
    @simpl.eval_source_is_int(
      "if #Left(41) is #Left(x) then x + 1 | true then 0 else -1", 42,
    ),
  )
}

///|
test "leading pipe forces if multi-route even with multi-is first branch" {
  let code =
    #| if
    #| | #Some(1) is
    #|   | #Some(x) then x
    #|   | _ then 0
    #|   end
    #| else -1
  assert_true(@simpl.eval_source_is_int(code, 1))
}

///|
test "and else closes and split and end closes if" {
  let code =
    #| if true and
    #|   | false then 1
    #|   else 2
    #| end
  assert_true(@simpl.eval_source_is_int(code, 2))
}

///|
test "if else already closes if and trailing end is rejected" {
  let code =
    #| if true and #Some(42) is
    #|   #Some(42) then 1
    #|   else 2
    #| end
  assert_true(@simpl.parse_is_error(code))
}

///|
test "and end does not close outer if multi-route" {
  let code =
    #| if true and
    #| | false then 1
    #| | true then 2
    #| end
  assert_true(@simpl.parse_is_error(code))
}

///|
test "or closes only current split point" {
  let code =
    #| if
    #| | true and
    #|   | false then 1
    #|   | true then 2
    #|   or
    #| | true then 3
    #| else 0
  assert_true(@simpl.eval_source_is_int(code, 2))
}
