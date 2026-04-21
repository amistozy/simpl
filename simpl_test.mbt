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
      @simpl.lambda(
        @simpl.strings1("y"),
        @simpl.add(@simpl.var_ref("x"), @simpl.var_ref("y")),
      ),
      @simpl.let_in(
        "x",
        @simpl.int_lit(100),
        @simpl.call(@simpl.var_ref("f"), @simpl.exprs1(@simpl.int_lit(5))),
      ),
    ),
  )
  assert_true(@simpl.eval_is_int(expr, 15))
}

///|
test "higher order function" {
  let expr = @simpl.call(
    @simpl.lambda(
      @simpl.strings1("f"),
      @simpl.call(@simpl.var_ref("f"), @simpl.exprs1(@simpl.int_lit(41))),
    ),
    @simpl.exprs1(
      @simpl.lambda(
        @simpl.strings1("x"),
        @simpl.add(@simpl.var_ref("x"), @simpl.int_lit(1)),
      ),
    ),
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
test "ref basics and assignment expression value" {
  let code =
    #| let r = ref 1 in
    #| let x = (r := 3) in
    #| !r + x
  assert_true(@simpl.eval_source_is_int(code, 6))
}

///|
test "man or boy with refs (mutual recursion through cells)" {
  let code =
    #| let p_ref = ref nil in
    #| let q_ref = ref nil in
    #| let p(n) = if n == 0 then 1 else (!q_ref)(n - 1) in
    #| let q(n) = if n == 0 then 0 else (!p_ref)(n - 1) in
    #| let _ = (p_ref := p) in
    #| let _ = (q_ref := q) in
    #| (!p_ref)(10)
  assert_true(@simpl.eval_source_is_int(code, 1))
}

///|
test "man or boy (Knuth) translated from let rec version" {
  let code =
    #| let a_ref = ref nil in
    #| let a(k, x1, x2, x3, x4, x5) =
    #|   if k < 1 then
    #|     x4() + x5()
    #|   else
    #|     let m = ref k in
    #|     let b_ref = ref nil in
    #|     let b() =
    #|       let _ = (m := !m - 1) in
    #|       (!a_ref)(!m, !b_ref, x1, x2, x3, x4)
    #|     in
    #|     let _ = (b_ref := b) in
    #|     (!b_ref)()
    #| in
    #| let _ = (a_ref := a) in
    #| (!a_ref)(3, fn() => 1, fn() => -1, fn() => -1, fn() => 1, fn() => 0)
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
