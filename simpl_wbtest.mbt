///|
/// Whitebox: evaluate with preloaded environment
test "eval_with_env reads env chain" {
  let env = @hashmap.singleton("x", VInt(7))
  assert_true(
    try eval_with_env(Var("x"), env) catch {
      _ => false
    } noraise {
      VInt(v) => v == 7
      _ => false
    },
  )
}

///|
test "inner let shadows outer binding" {
  let expr = Let(PBind("x"), IntLit(1), Let(PBind("x"), IntLit(2), Var("x")))
  assert_true(eval_is_int(expr, 2))
}

///|
test "calling non function errors" {
  let expr = Call(IntLit(1), [])
  assert_true(eval_is_error(expr))
}

///|
test "record equality" {
  let left = Record([("a", IntLit(1)), ("b", BoolLit(true))])
  let right = Record([("a", IntLit(1)), ("b", BoolLit(true))])
  assert_true(eval_is_bool(Binary(Eq, left, right), true))
}

///|
test "parser preserves do sugar before desugar" {
  match parse("do 1 in 2") {
    SLocated(_, SDo(SLocated(_, SIntLit(1)), SLocated(_, SIntLit(2)))) =>
      assert_true(true)
    _ => assert_true(false)
  }
}

///|
test "desugar lowers do to ignored let" {
  match desugar(SDo(SIntLit(1), SIntLit(2))) {
    Let(PBind("_"), IntLit(1), IntLit(2)) => assert_true(true)
    _ => assert_true(false)
  }
}

///|
test "parser preserves let function sugar before desugar" {
  match parse("let add(x) = x + 1 in add(41)") {
    SLocated(_, SLetFun("add", [PBind("x")], _, _)) => assert_true(true)
    _ => assert_true(false)
  }
}

///|
test "desugared surface ast evaluates as core ast" {
  let expr = SDo(SRefSet(SVar("r"), SIntLit(42)), SRefGet(SVar("r")))
  assert_true(
    eval_is_int(Let(PBind("r"), RefNew(IntLit(0)), desugar(expr)), 42),
  )
}
