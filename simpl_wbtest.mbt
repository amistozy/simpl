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
