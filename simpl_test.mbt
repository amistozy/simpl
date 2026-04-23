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
    #| if 1 != 2 and 2 <= 2 and 3 >= 2 then 1 else 0
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
test "non-exhaustive match reports unmatched value" {
  assert_eq(
    @simpl.eval_error_text("match 42 with 0 -> 0"),
    Some("non-exhaustive match: no case matched value 42 at 1:1-21"),
  )
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
    #| do false and (r := 1 == 1) in
    #| !r
  assert_true(@simpl.eval_source_is_int(code, 0))
}

///|
test "or short-circuits right-hand side" {
  let code =
    #| let r = ref 0 in
    #| do true or (r := 1 == 1) in
    #| !r
  assert_true(@simpl.eval_source_is_int(code, 0))
}

///|
test "and returns the actual operand value" {
  let code =
    #| "left" and "right"
  assert_true(@simpl.eval_source_is_string(code, "right"))
}

///|
test "or returns the actual operand value" {
  let code =
    #| nil or "fallback"
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
    #| match #Left(41) with
    #| | #Left(x) -> x + 1
    #| | #Right(y) -> y
  assert_true(@simpl.eval_source_is_int(code, 42))
}

///|
test "variant can be stored in let binding" {
  let code =
    #| let v = #Right(42) in
    #| match v with
    #| | #Left(x) -> x
    #| | #Right(y) -> y
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
    #| match [1, 2] with
    #| | [x, y] -> x + y
    #| | [] -> 0
  assert_true(@simpl.eval_source_is_int(code, 3))
}

///|
test "empty list pattern match" {
  let code =
    #| match [] with
    #| | [] -> 42
    #| | [x] -> x
  assert_true(@simpl.eval_source_is_int(code, 42))
}

///|
test "nested list pattern match" {
  let code =
    #| match [#Left(1), #Right(2)] with
    #| | [#Left(x), #Right(y)] -> x + y
  assert_true(@simpl.eval_source_is_int(code, 3))
}

///|
test "list rest pattern supports fixed prefix and suffix" {
  let code =
    #| match [1, 2, 3, 4, 5, 6] with
    #| | [a, b, ..c, d, e] ->
    #|     match c with
    #|     | [x, y] -> a + b + d + e + x + y
    #|     | _ -> 0
    #|     end
    #| | _ -> 0
  assert_true(@simpl.eval_source_is_int(code, 21))
}

///|
test "list rest pattern allows empty middle slice" {
  let code =
    #| match [10, 20, 30, 40] with
    #| | [a, b, ..c, d, e] ->
    #|     match c with
    #|     | [] -> a + b + d + e
    #|     | _ -> 0
    #|     end
    #| | _ -> 0
  assert_true(@simpl.eval_source_is_int(code, 100))
}

///|
test "list rest pattern can ignore the middle with bare dotdot" {
  let code =
    #| match [1, 2, 3, 4, 5] with
    #| | [a, .., z] -> a + z
    #| | _ -> 0
  assert_true(@simpl.eval_source_is_int(code, 6))
}

///|
test "list rest pattern can ignore middle before fixed suffix" {
  let code =
    #| match [10, 20, 30, 40, 50] with
    #| | [a, .., y, z] -> a + y + z
    #| | _ -> 0
  assert_true(@simpl.eval_source_is_int(code, 100))
}

///|
test "list rest pattern works with nested patterns" {
  let code =
    #| match [#Left(1), #Right(2), #Right(3), #Left(4)] with
    #| | [#Left(a), ..mid, #Left(b)] ->
    #|     match mid with
    #|     | [#Right(x), #Right(y)] -> a + x + y + b
    #|     | _ -> 0
    #|     end
    #| | _ -> 0
  assert_true(@simpl.eval_source_is_int(code, 10))
}

///|
test "list pattern rejects multiple rest bindings" {
  let code =
    #| match [1, 2, 3] with
    #| | [..a, ..b] -> 0
    #| | _ -> 1
  assert_true(@simpl.parse_is_error(code))
}

///|
test "nested variant pattern match" {
  let code =
    #| match #Outer(#Inner(41)) with
    #| | #Outer(#Inner(x)) -> x + 1
  assert_true(@simpl.eval_source_is_int(code, 42))
}

///|
test "variant carrying list pattern match" {
  let code =
    #| match #Wrap([10, 32]) with
    #| | #Wrap([x, y]) -> x + y
  assert_true(@simpl.eval_source_is_int(code, 42))
}

///|
test "match guards can refine successful pattern bindings" {
  let code =
    #| match #Some(42) with
    #| | #Some(x) if x < 0 -> 0
    #| | #Some(x) if x >= 42 -> x
    #| | _ -> -1
  assert_true(@simpl.eval_source_is_int(code, 42))
}

///|
test "match guards can use bindings from nested patterns" {
  let code =
    #| match {pair: [10, 32]} with
    #| | {pair: [x, y]} if x + y == 42 -> y
    #| | _ -> 0
  assert_true(@simpl.eval_source_is_int(code, 32))
}

///|
test "guard failure falls through to later cases" {
  let code =
    #| match [20, 22] with
    #| | [x, y] if x > y -> x
    #| | [x, y] -> x + y
  assert_true(@simpl.eval_source_is_int(code, 42))
}

///|
test "or patterns match any alternative" {
  let code =
    #| match #Right(42) with
    #| | #Left(x) | #Right(x) -> x
    #| | _ -> 0
  assert_true(@simpl.eval_source_is_int(code, 42))
}

///|
test "or patterns work with guards" {
  let code =
    #| match [20, 22] with
    #| | [x, 0] | [0, x] -> x
    #| | [x, y] | [y, x] if x + y == 42 -> y
    #| | _ -> 0
  assert_true(@simpl.eval_source_is_int(code, 22))
}

///|
test "or patterns require the same bindings on each branch" {
  let code =
    #| match #Left(42) with
    #| | #Left(x) | #Right(y) -> x
    #| | _ -> 0
  assert_true(@simpl.parse_is_error(code))
}

///|
test "match end disambiguates nested match cases" {
  let code =
    #| match 41 with
    #| | 42 ->
    #|   match 41 with
    #|   | 42 -> 0
    #|   | _ -> 1
    #|   end
    #| | _ -> 2
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
    #| match 42 with
    #| | 0 -> 0
    #| | 42 -> 1
  let string_code =
    #| match "moon" with
    #| | "sun" -> 0
    #| | "moon" -> 1
  let bool_code =
    #| match false with
    #| | true -> 1
    #| | false -> 42
  let nil_code =
    #| match nil with
    #| | nil -> 42
    #| | _ -> 0
  assert_true(@simpl.eval_source_is_int(int_code, 1))
  assert_true(@simpl.eval_source_is_int(string_code, 1))
  assert_true(@simpl.eval_source_is_int(bool_code, 42))
  assert_true(@simpl.eval_source_is_int(nil_code, 42))
}

///|
test "is expression bindings flow into then branch" {
  let code =
    #| if [1, 2, 3] is [head, ..tail] then head else 0
  let and_code =
    #| if [1, 2, 3] is [head, ..tail] and head == 1 then
    #|   tail is [2, 3]
    #| else
    #|   false
  assert_true(@simpl.eval_source_is_int(code, 1))
  assert_true(@simpl.eval_source_is_bool(and_code, true))
}

///|
test "is expression bindings flow through top-level and" {
  let code =
    #| let xs = [1, 2, 3] in
    #| xs is [x, ..] and x > 0
  assert_true(@simpl.eval_source_is_bool(code, true))
}

///|
test "is expression supports composite and or patterns" {
  let list_code =
    #| [#Left(1), #Right(2)] is [#Left(_), #Right(2)]
  let record_code =
    #| {left: #Some(10), right: [1, 32]} is {left: #Some(_), right: [1, 32]}
  let or_code =
    #| #Right(42) is #Left(_) | #Right(_)
  let miss_code =
    #| {x: 1, y: 2} is {x: 1, y: 3}
  assert_true(@simpl.eval_source_is_bool(list_code, true))
  assert_true(@simpl.eval_source_is_bool(record_code, true))
  assert_true(@simpl.eval_source_is_bool(or_code, true))
  assert_true(@simpl.eval_source_is_bool(miss_code, false))
}

///|
test "record patterns match and can nest other patterns" {
  let code =
    #| match {left: #Some(10), right: [1, 32], flag: true} with
    #| | {left: #Some(x), right: [1, y], flag: true} -> x + y
    #| | _ -> 0
  assert_true(@simpl.eval_source_is_int(code, 42))
}

///|
test "record patterns support shorthand field binding" {
  let code =
    #| match {x: 10, y: 32} with
    #| | {x, y} -> x + y
  assert_true(@simpl.eval_source_is_int(code, 42))
}
