///|
/// Blackbox: basic arithmetic and dynamic type checks
test "int arithmetic" {
  let expr = @simpl.add(@simpl.int_lit(1), @simpl.int_lit(2))
  assert_true(@simpl.eval_is_int(expr, 3))
}

///|
test "string concatenation" {
  let expr = @simpl.add(
    @simpl.string_lit("hello "),
    @simpl.string_lit("moonbit"),
  )
  assert_true(@simpl.eval_is_string(expr, "hello moonbit"))
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
  let expr = @simpl.add(@simpl.int_lit(1), @simpl.bool_lit(true))
  assert_true(@simpl.eval_is_error(expr))
}

///|
test "comparison and logic operators" {
  let lt_expr = @simpl.lt(@simpl.int_lit(1), @simpl.int_lit(2))
  let eq_expr = @simpl.eq(@simpl.int_lit(3), @simpl.int_lit(3))
  let logic_expr = @simpl.logic_and(lt_expr, eq_expr)
  assert_true(@simpl.eval_is_bool(logic_expr, true))
  let gt_expr = @simpl.gt(@simpl.int_lit(4), @simpl.int_lit(1))
  let or_expr = @simpl.logic_or(gt_expr, @simpl.bool_lit(false))
  assert_true(@simpl.eval_is_bool(or_expr, true))
}

///|
test "extended comparisons (!= <= >=)" {
  let code =
    #| if 1 != 2 && 2 <= 2 && 3 >= 2 then 1 else 0
  assert_true(@simpl.eval_source_is_int(code, 1))
}

///|
/// Blackbox: functional closures with lexical environment
test "closure captures lexical env" {
  let expr = @simpl.let_in(
    "x",
    @simpl.int_lit(10),
    @simpl.let_in(
      "f",
      @simpl.lambda(["y"], @simpl.add(@simpl.var_ref("x"), @simpl.var_ref("y"))),
      @simpl.let_in(
        "x",
        @simpl.int_lit(100),
        @simpl.call(@simpl.var_ref("f"), [@simpl.int_lit(5)]),
      ),
    ),
  )
  assert_true(@simpl.eval_is_int(expr, 15))
}

///|
test "higher order function" {
  let expr = @simpl.call(
    @simpl.lambda(["f"], @simpl.call(@simpl.var_ref("f"), [@simpl.int_lit(41)])),
    [@simpl.lambda(["x"], @simpl.add(@simpl.var_ref("x"), @simpl.int_lit(1)))],
  )
  assert_true(@simpl.eval_is_int(expr, 42))
}

///|
/// Blackbox: parser + evaluator
test "eval_source honors operator precedence" {
  assert_true(@simpl.eval_source_is_int("1 + 2 * 3", 7))
}

///|
test "eval_source supports let if lambda call" {
  let code =
    #| let x = 10 in 
    #| let f(y) = x + y in 
    #| if true then f(5) else 0
  assert_true(@simpl.eval_source_is_int(code, 15))
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
test "UCS follow-up branches require pipe" {
  assert_true(@simpl.parse_is_error("if false then 0 true then 1 else 2"))
  assert_true(
    @simpl.parse_is_error(
      "if #Right(1) is #Left(x) then x #Right(y) then y else 0",
    ),
  )
}

///|
test "UCS pattern guard with if is rejected" {
  assert_true(
    @simpl.parse_is_error("if #Some(1) is | #Some(x) if x > 0 then x else 0"),
  )
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
    @simpl.parse_error_text("1 2"),
    Some("unexpected token after expression: int at 1:3-4"),
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
    #| let r = ref 1 in
    #| let x = (r := 3) in
    #| !r + x
  assert_true(@simpl.eval_source_is_int(code, 6))
}

///|
test "runtime error includes source position" {
  assert_eq(@simpl.eval_error_text("1 / 0"), Some("division by zero at 1:1-6"))
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
test "field access type error reports expected and actual value" {
  assert_eq(
    @simpl.eval_error_text("1.x"),
    Some("type error: operator '.' expected Record, got Int(1) at 1:1-4"),
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
    @simpl.eval_error_text("{x: 1}.y"),
    Some("missing field: record has no field 'y' in Record(1 fields) at 1:1-9"),
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
    @simpl.eval_error_text("let f(x) = x in f(1, 2)"),
    Some("arity error: expected 1 arguments, got 2 at 1:17-24"),
  )
}

///|
test "pattern match failure reports expected pattern and actual value" {
  assert_eq(
    @simpl.eval_error_text("let [x, y] = [1] in x"),
    Some("pattern match failure: expected [x, y], got [1] at 1:5-22"),
  )
}

///|
test "if is requires else or end terminator" {
  assert_true(@simpl.parse_is_error("if 42 is 0 then 0"))
}

///|
test "man or boy with refs (mutual recursion through cells)" {
  let code =
    #| let p_ref = ref nil in
    #| let q_ref = ref nil in
    #| let p(n) = if n == 0 then 1 else (!q_ref)(n - 1) in
    #| let q(n) = if n == 0 then 0 else (!p_ref)(n - 1) in
    #| do p_ref := p in
    #| do q_ref := q in
    #| (!p_ref)(10)
  assert_true(@simpl.eval_source_is_int(code, 1))
}

///|
test "man or boy (Knuth) translated from let rec version" {
  let code =
    #| let rec a(k, x1, x2, x3, x4, x5) =
    #|   if k < 1 then
    #|     x4() + x5()
    #|   else
    #|     let m = ref k in
    #|     let rec b() =
    #|       do m := !m - 1 in
    #|       a(!m, b, x1, x2, x3, x4)
    #|     in
    #|     b()
    #| in
    #| a(3, fn() => 1, fn() => -1, fn() => -1, fn() => 1, fn() => 0)
  assert_true(@simpl.eval_source_is_int(code, 0))
}

///|
test "let rec factorial" {
  let code =
    #| let rec fact(n) =
    #|   if n == 0 then 1 else n * fact(n - 1)
    #| in
    #| fact(6)
  assert_true(@simpl.eval_source_is_int(code, 720))
}

///|
test "let rec supports lexical capture" {
  let code =
    #| let x = 3 in
    #| let rec f(n) =
    #|   if n == 0 then x else f(n - 1)
    #| in
    #| f(4)
  assert_true(@simpl.eval_source_is_int(code, 3))
}

///|
test "let function sugar equals lambda binding" {
  let code =
    #| let add2(x) = x + 2 in
    #| add2(40)
  assert_true(@simpl.eval_source_is_int(code, 42))
}

///|
test "do sugar equals let _ = ... in ..." {
  let code =
    #| let r = ref 0 in
    #| do r := 1 in
    #| do r := !r + 41 in
    #| !r
  assert_true(@simpl.eval_source_is_int(code, 42))
}

///|
test "do sugar nests like let _ bindings" {
  let code =
    #| let r = ref 0 in
    #| do r := 1 in
    #| do r := !r + 1 in
    #| do r := !r + 1 in
    #| !r
  assert_true(@simpl.eval_source_is_int(code, 3))
}

///|
test "and short-circuits right-hand side" {
  let code =
    #| let r = ref 0 in
    #| do false && (r := 1 == 1) in
    #| !r
  assert_true(@simpl.eval_source_is_int(code, 0))
}

///|
test "or short-circuits right-hand side" {
  let code =
    #| let r = ref 0 in
    #| do true || (r := 1 == 1) in
    #| !r
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
test "record literal and field access" {
  let code =
    #| {name: "moon", count: 2}.name
  assert_true(@simpl.eval_source_is_string(code, "moon"))
}

///|
test "record literal supports field shorthand" {
  let code =
    #| let x = 42 in {x, y: 43}.x
  assert_true(@simpl.eval_source_is_int(code, 42))
}

///|
test "nested record fields" {
  let code =
    #| {user: {name: "moon", active: true}}.user.name
  assert_true(@simpl.eval_source_is_string(code, "moon"))
}

///|
test "record field access can be used in expressions" {
  let code =
    #| let p = {x: 10, y: 32} in 
    #| p.x + p.y
  assert_true(@simpl.eval_source_is_int(code, 42))
}

///|
test "record destructuring binds fields" {
  let code =
    #| let {x, y} = {x: 10, y: 32} in 
    #| x + y
  assert_true(@simpl.eval_source_is_int(code, 42))
}

///|
test "record destructuring supports renaming" {
  let code =
    #| let {x: left, y: right} = {x: 10, y: 32} in 
    #| left + right
  assert_true(@simpl.eval_source_is_int(code, 42))
}

///|
test "let supports general patterns" {
  let code =
    #| let #Pair([x, y]) = #Pair([10, 32]) in
    #| x + y
  assert_true(@simpl.eval_source_is_int(code, 42))
}

///|
test "variant literal and match" {
  let code =
    #| if #Left(41) is
    #| | #Left(x) then x + 1
    #| | #Right(y) then y
    #| end
  assert_true(@simpl.eval_source_is_int(code, 42))
}

///|
test "variant can be stored in let binding" {
  let code =
    #| let v = #Right(42) in
    #| if v is
    #| | #Left(x) then x
    #| | #Right(y) then y
    #| end
  assert_true(@simpl.eval_source_is_int(code, 42))
}

///|
test "list literal and equality" {
  let code =
    #| [1, 2, 3]
  match @simpl.eval_source(code) {
    @simpl.VList(items) => {
      assert_true(items.length() == 3)
      match items[0] {
        @simpl.VInt(v) => assert_true(v == 1)
        _ => assert_true(false)
      }
      match items[1] {
        @simpl.VInt(v) => assert_true(v == 2)
        _ => assert_true(false)
      }
      match items[2] {
        @simpl.VInt(v) => assert_true(v == 3)
        _ => assert_true(false)
      }
    }
    _ => assert_true(false)
  }
}

///|
test "list equality is recursive" {
  let code =
    #| [1, [2, 3]] == [1, [2, 3]]
  assert_true(@simpl.eval_source_is_bool(code, true))
}

///|
test "list pattern match" {
  let code =
    #| if [1, 2] is
    #| | [x, y] then x + y
    #| | [] then 0
    #| end
  assert_true(@simpl.eval_source_is_int(code, 3))
}

///|
test "empty list pattern match" {
  let code =
    #| if [] is
    #| | [] then 42
    #| | [x] then x
    #| end
  assert_true(@simpl.eval_source_is_int(code, 42))
}

///|
test "nested list pattern match" {
  let code =
    #| if [#Left(1), #Right(2)] is
    #| | [#Left(x), #Right(y)] then x + y
    #| end
  assert_true(@simpl.eval_source_is_int(code, 3))
}

///|
test "list rest pattern supports fixed prefix and suffix" {
  let code =
    #| if [1, 2, 3, 4, 5, 6] is
    #| | [a, b, ..c, d, e] then
    #|     if c is
    #|     | [x, y] then a + b + d + e + x + y
    #|     else 0
    #| else 0
  assert_true(@simpl.eval_source_is_int(code, 21))
}

///|
test "list rest pattern allows empty middle slice" {
  let code =
    #| if [10, 20, 30, 40] is
    #| | [a, b, ..c, d, e] then
    #|     if c is
    #|     | [] then a + b + d + e
    #|     else 0
    #| else 0
  assert_true(@simpl.eval_source_is_int(code, 100))
}

///|
test "list rest pattern can ignore the middle with bare dotdot" {
  let code =
    #| if [1, 2, 3, 4, 5] is
    #| | [a, .., z] then a + z
    #| else 0
  assert_true(@simpl.eval_source_is_int(code, 6))
}

///|
test "list rest pattern can ignore middle before fixed suffix" {
  let code =
    #| if [10, 20, 30, 40, 50] is
    #| | [a, .., y, z] then a + y + z
    #| else 0
  assert_true(@simpl.eval_source_is_int(code, 100))
}

///|
test "list rest pattern works with nested patterns" {
  let code =
    #| if [#Left(1), #Right(2), #Right(3), #Left(4)] is
    #| | [#Left(a), ..mid, #Left(b)] then
    #|     if mid is
    #|     | [#Right(x), #Right(y)] then a + x + y + b
    #|     else 0
    #| else 0
  assert_true(@simpl.eval_source_is_int(code, 10))
}

///|
test "list pattern rejects multiple rest bindings" {
  let code =
    #| if [1, 2, 3] is
    #| | [..a, ..b] then 0
    #| else 1
  assert_true(@simpl.parse_is_error(code))
}

///|
test "nested variant pattern match" {
  let code =
    #| if #Outer(#Inner(41)) is
    #| | #Outer(#Inner(x)) then x + 1
    #| end
  assert_true(@simpl.eval_source_is_int(code, 42))
}

///|
test "variant carrying list pattern match" {
  let code =
    #| if #Wrap([10, 32]) is
    #| | #Wrap([x, y]) then x + y
    #| end
  assert_true(@simpl.eval_source_is_int(code, 42))
}

///|
test "match guards can refine successful pattern bindings" {
  let code =
    #| if #Some(42) is
    #| | #Some(x) and x < 0 then 0
    #| | #Some(x) and x >= 42 then x
    #| else -1
  assert_true(@simpl.eval_source_is_int(code, 42))
}

///|
test "match guards can use bindings from nested patterns" {
  let code =
    #| if {pair: [10, 32]} is
    #| | {pair: [x, y]} and x + y == 42 then y
    #| else 0
  assert_true(@simpl.eval_source_is_int(code, 32))
}

///|
test "match guard is bindings flow into case body" {
  let code =
    #| let f(x) = #Some(x + 1) in
    #| if [1, 2] is
    #| | [x, ..] and f(x) is 
    #|   | #Some(y) then y
    #|   end
    #| else 0
  assert_true(@simpl.eval_source_is_int(code, 2))
}

///|
test "guard failure falls through to later cases" {
  let code =
    #| if [20, 22] is
    #| | [x, y] and x > y then x
    #| | [x, y] then x + y
    #| end
  assert_true(@simpl.eval_source_is_int(code, 42))
}

///|
test "or patterns match any alternative" {
  let code =
    #| if #Right(42) is
    #| | #Left(x) | #Right(x) then x
    #| else 0
  assert_true(@simpl.eval_source_is_int(code, 42))
}

///|
test "or patterns work with guards" {
  let code =
    #| if [20, 22] is
    #| | [x, 0] | [0, x] then x
    #| | [x, y] | [y, x] and 
    #|   | x + y == 42 then y
    #|   end
    #| else 0
  assert_true(@simpl.eval_source_is_int(code, 22))
}

///|
test "or patterns require the same bindings on each branch" {
  let code =
    #| if #Left(42) is
    #| | #Left(x) | #Right(y) then x
    #| else 0
  assert_true(@simpl.parse_is_error(code))
}

///|
test "match end disambiguates nested match cases" {
  let code =
    #| if 41 is
    #| | 42 then
    #|     if 41 is
    #|     | 42 then 0
    #|     else 1
    #| else 2
  assert_true(@simpl.eval_source_is_int(code, 2))
}

///|
test "lambda parameters support patterns" {
  let code =
    #| (fn(#Pair(x), {y}) => x + y)(#Pair(10), {y: 32})
  assert_true(@simpl.eval_source_is_int(code, 42))
}

///|
test "let function sugar supports parameter patterns" {
  let code =
    #| let add_pair(#Pair(x), [y, z]) = x + y + z in
    #| add_pair(#Pair(10), [20, 12])
  assert_true(@simpl.eval_source_is_int(code, 42))
}

///|
test "let rec supports parameter patterns" {
  let code =
    #| let rec sum_pair(#Pair(x), acc) =
    #|   if x == 0 then acc else sum_pair(#Pair(x - 1), acc + 1)
    #| in
    #| sum_pair(#Pair(42), 0)
  assert_true(@simpl.eval_source_is_int(code, 42))
}

///|
test "literal patterns match primitive values" {
  let int_code =
    #| if 42 is
    #| | 0 then 0
    #| | 42 then 1
    #| end
  let string_code =
    #| if "moon" is
    #| | "sun" then 0
    #| | "moon" then 1
    #| end
  let bool_code =
    #| if false is
    #| | true then 1
    #| | false then 42
    #| end
  let nil_code =
    #| if nil is
    #| | nil then 42
    #| else 0
  assert_true(@simpl.eval_source_is_int(int_code, 1))
  assert_true(@simpl.eval_source_is_int(string_code, 1))
  assert_true(@simpl.eval_source_is_int(bool_code, 42))
  assert_true(@simpl.eval_source_is_int(nil_code, 42))
}

///|
test "UCS boolean condition cases are whitespace insensitive" {
  let spaced =
    #| if
    #| | false then 0
    #| | 1 + 1 == 2 then 42
    #| else 1
  let flat = "if false then 0 | 1 + 1 == 2 then 42 else 1"
  assert_true(@simpl.eval_source_is_int(spaced, 42))
  assert_true(@simpl.eval_source_is_int(flat, 42))
}

///|
test "UCS pattern split replaces match syntax" {
  let code =
    #| if #Right(42) is
    #| | #Left(x) then x
    #| | #Right(y) then y
    #| else 0
  assert_true(@simpl.eval_source_is_int(code, 42))
}

///|
test "UCS pattern split supports guards and end" {
  let code =
    #| if [20, 22] is
    #| | [x, y] and x > y then x
    #| | [x, y] and x + y == 42 then y
    #| else 0
    #| end
  assert_true(@simpl.eval_source_is_int(code, 22))
}

///|
test "UCS pattern guards can start with and" {
  let code =
    #| if [20, 22] is
    #| | [x, y] and 
    #|   | x + y == 42 then y
    #|   end
    #| else 0
  assert_true(@simpl.eval_source_is_int(code, 22))
}

///|
test "UCS pattern case supports nested split sugar after and" {
  let code =
    #| let compute(input) = if input > 0 then #Some(input + 1) else nil in
    #| if #Left(1) is
    #| | #Right(nil) then 0
    #| | #Right(#Some(cached)) then cached
    #| | #Left(input) and compute(input) is
    #|   | nil then 0
    #|   | #Some(result) then result
    #|   end
    #| else -1
  assert_true(@simpl.eval_source_is_int(code, 2))
}

///|
test "UCS nested guard branches after and" {
  let code =
    #| let x = #Some(42) in
    #| if x is
    #| | #Some(y) and
    #|   | y > 0 then 1
    #|   | y == 0 then 2
    #|   end
    #| else 3
  assert_true(@simpl.eval_source_is_int(code, 1))
}

///|
test "UCS and multi-branch can stop with or" {
  let code =
    #| let x = #Some(42) in
    #| if x is
    #| | #Some(y) and
    #|   | y < 0 then 0
    #|   or
    #| | #Some(y) then y
    #| end
  assert_true(@simpl.eval_source_is_int(code, 42))
}

///|
test "UCS and is multi-branch can stop with or" {
  let code =
    #| let f(x) = #Some(x) in
    #| if #Some(42) is
    #| | #Some(v) and f(v) is
    #|   | #Some(n) and n < 0 then 0
    #|   or
    #| | #Some(v) then v
    #| end
  assert_true(@simpl.eval_source_is_int(code, 42))
}

///|
test "UCS snippets from ucs.txt parse" {
  let snippet1 =
    #| if x is #Some(a) and y is #Some(b) then a + b else 0
  let snippet2 =
    #| if foo(u, v, w) is
    #| | #Some(x) and x is
    #|   | #Left(_) then "left-defined"
    #|   | #Right(_) then "right-defined"
    #|   end
    #| | nil then "undefined"
    #| end
  let snippet3 =
    #| if [xs, ys] is
    #| | [[x, ..], [y, ..]] and 
    #|   | x + y > 0 then 1
    #|   end
    #| | [[], []] then 2
    #| else 3
  assert_true(@simpl.parse_is_ok(snippet1))
  assert_true(@simpl.parse_is_ok(snippet2))
  assert_true(@simpl.parse_is_ok(snippet3))
}

///|
test "UCS pattern split is not indentation sensitive" {
  let pretty =
    #| if [1, 2, 3] is
    #| | [head, ..tail] then head
    #| else 0
  let flat = "if [1, 2, 3] is [head, ..tail] then head else 0"
  assert_true(@simpl.eval_source_is_int(pretty, 1))
  assert_true(@simpl.eval_source_is_int(flat, 1))
}

///|
test "record patterns match and can nest other patterns" {
  let code =
    #| if {left: #Some(10), right: [1, 32], flag: true} is
    #| | {left: #Some(x), right: [1, y], flag: true} then x + y
    #| else 0
  assert_true(@simpl.eval_source_is_int(code, 42))
}

///|
test "record patterns support shorthand field binding" {
  let code =
    #| if {x: 10, y: 32} is
    #| | {x, y} then x + y
    #| end
  assert_true(@simpl.eval_source_is_int(code, 42))
}
