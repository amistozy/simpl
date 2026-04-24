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
    #| | false then 1
    #| else 2
    #| end
  assert_true(@simpl.eval_source_is_int(code, 2))
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
