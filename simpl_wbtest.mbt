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
  assert_true(
    try eval(expr) catch {
      _ => false
    } noraise {
      VInt(v) => v == 2
      _ => false
    },
  )
}

///|
test "calling non function errors" {
  let expr = Call(IntLit(1), [])
  assert_true(
    try {
      ignore(eval(expr))
      false
    } catch {
      _ => true
    },
  )
}

///|
test "record equality" {
  let left = Record([("a", IntLit(1)), ("b", BoolLit(true))])
  let right = Record([("a", IntLit(1)), ("b", BoolLit(true))])
  assert_true(
    try eval(Binary(Eq, left, right)) catch {
      _ => false
    } noraise {
      VBool(v) => v
      _ => false
    },
  )
}

///|
test "parser preserves do sugar before desugar" {
  match parse("do 1; 2") {
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
  match parse("let add(x) = x + 1; add(41)") {
    SLocated(_, SLetFun("add", [SParam(SPBind("x"), None)], _, _)) =>
      assert_true(true)
    _ => assert_true(false)
  }
}

///|
test "parser preserves let single-param function sugar before desugar" {
  match parse("let add x = x + 1; add(41)") {
    SLocated(_, SLetFun("add", [SParam(SPBind("x"), None)], _, _)) =>
      assert_true(true)
    _ => assert_true(false)
  }
}

///|
test "parser lowers param default lambda sugar to default lambda expr" {
  match parse("let foo(f(x) = x) = f(42); foo()") {
    SLocated(
      _,
      SLetFun(
        "foo",
        [SParam(SPBind("f"), Some(SLocated(_, SLambda(_, _))))],
        _,
        _
      )
    ) => assert_true(true)
    _ => assert_true(false)
  }
}

///|
test "parser lowers single-param default lambda sugar to default lambda expr" {
  match parse("let foo(f x = x) = f(42); foo()") {
    SLocated(
      _,
      SLetFun(
        "foo",
        [SParam(SPBind("f"), Some(SLocated(_, SLambda(_, _))))],
        _,
        _
      )
    ) => assert_true(true)
    _ => assert_true(false)
  }
}

///|
test "parser rewrites trailing arg sugar into positional call arg" {
  match parse("f x") {
    SLocated(
      _,
      SCall(SLocated(_, SVar("f")), [SArgPos(SLocated(_, SVar("x")))])
    ) => assert_true(true)
    _ => assert_true(false)
  }
}

///|
test "parser appends trailing arg after parenthesized call" {
  match parse("f(1; 2) 3") {
    SLocated(
      _,
      SCall(
        SLocated(_, SVar("f")),
        [
          SArgPos(SLocated(_, SIntLit(1))),
          SArgPos(SLocated(_, SIntLit(2))),
          SArgPos(SLocated(_, SIntLit(3))),
        ]
      )
    ) => assert_true(true)
    _ => assert_true(false)
  }
}

///|
test "parser supports single-param named arg lambda sugar" {
  match parse("apply(f x = x + 1)") {
    SLocated(
      _,
      SCall(
        SLocated(_, SVar("apply")),
        [SArgNamed("f", SLocated(_, SLambda(_, _)))]
      )
    ) => assert_true(true)
    _ => assert_true(false)
  }
}

///|
test "parser binds trailing lambda as a single lowest-precedence arg" {
  match parse("foo fn(x) = x + 1") {
    SLocated(
      _,
      SCall(SLocated(_, SVar("foo")), [SArgPos(SLocated(_, SLambda(_, _)))])
    ) => assert_true(true)
    _ => assert_true(false)
  }
}

///|
test "parser supports fn param shorthand without parentheses" {
  match parse("fn x = x + 1") {
    SLocated(_, SLambda([SParam(SPBind("x"), None)], _)) => assert_true(true)
    _ => assert_true(false)
  }
}

///|
test "parser makes trailing application right-associative" {
  match parse("f g x") {
    SLocated(
      _,
      SCall(
        SLocated(_, SVar("f")),
        [
          SArgPos(
            SLocated(
              _,
              SCall(SLocated(_, SVar("g")), [SArgPos(SLocated(_, SVar("x")))])
            )
          ),
        ]
      )
    ) => assert_true(true)
    _ => assert_true(false)
  }
}

///|
test "parser lowers let x += sugar into let with binary value" {
  match parse("let x += 1; x") {
    SLocated(
      _,
      SLet(
        SPBind("x"),
        SLocated(
          _,
          SBinary(Add, SLocated(_, SVar("x")), SLocated(_, SIntLit(1)))
        ),
        _
      )
    ) => assert_true(true)
    _ => assert_true(false)
  }
}

///|
test "parser preserves record pattern shorthand before desugar" {
  match parse("let {x; y = z} = {x = 1; y = 2}; x + z") {
    SLocated(
      _,
      SLet(
        SPRecord([SPRecordShorthand("x"), SPRecordField("y", SPBind("z"))]),
        _,
        _
      )
    ) => assert_true(true)
    _ => assert_true(false)
  }
}

///|
test "parser preserves let and group before desugar" {
  match parse("let x = 1 and y = 2; x + y") {
    SLocated(_, SLetAnd(bindings, _)) => assert_eq(bindings.length(), 2)
    _ => assert_true(false)
  }
}

///|
test "parser preserves let rec and group before desugar" {
  match parse("let rec f(x) = x and g(y) = y; f(1)") {
    SLocated(_, SLetRecAnd(defs, _)) => assert_eq(defs.length(), 2)
    _ => assert_true(false)
  }
}

///|
test "parser preserves let rec shorthand and group before desugar" {
  match parse("let rec f x = x and g y = y; f(1)") {
    SLocated(_, SLetRecAnd(defs, _)) => assert_eq(defs.length(), 2)
    _ => assert_true(false)
  }
}

///|
test "desugar lowers record pattern shorthand to field binding" {
  match
    desugar_pattern(
      SPRecord([SPRecordShorthand("x"), SPRecordField("y", SPBind("z"))]),
    ) {
    PRecord([("x", PBind("x")), ("y", PBind("z"))]) => assert_true(true)
    _ => assert_true(false)
  }
}

///|
test "parser preserves record shorthand before desugar" {
  match parse("{x; y = 1}") {
    SLocated(_, SRecord([SRecordShorthand("x"), SRecordField("y", _)])) =>
      assert_true(true)
    _ => assert_true(false)
  }
}

///|
test "parser preserves record single-param function field sugar" {
  match parse("{inc x = x + 1}") {
    SLocated(_, SRecord([SRecordField("inc", SLocated(_, SLambda(_, _)))])) =>
      assert_true(true)
    _ => assert_true(false)
  }
}

///|
test "desugar lowers record shorthand to field variable" {
  match
    desugar(SRecord([SRecordShorthand("x"), SRecordField("y", SIntLit(1))])) {
    Record([("x", Var("x")), ("y", IntLit(1))]) => assert_true(true)
    _ => assert_true(false)
  }
}

///|
test "desugared surface ast evaluates as core ast" {
  let expr = SDo(
    SBinary(RefSet, SVar("r"), SIntLit(42)),
    SUnary(Bang, SVar("r")),
  )
  assert_true(
    try
      eval(
        Let(PBind("r"), Call(Var("ref"), [ArgPos(IntLit(0))]), desugar(expr)),
      )
    catch {
      _ => false
    } noraise {
      VInt(v) => v == 42
      _ => false
    },
  )
}

///|
test "parser marks no-pipe multi-is first arm as standalone if" {
  match parse("if #Some(1) is | #Some(x) then x | _ then 0 end") {
    SLocated(_, SIf([SIfCondArm(_, SIfIs(_, _))], SLocated(_, SNilLit))) =>
      assert_true(true)
    _ => assert_true(false)
  }
}

///|
test "parser treats no-pipe single-is first arm as if multi-route" {
  assert_true(parse_is_error("if #Some(1) is #Some(x) then x"))
}

///|
test "parser still requires outer if closure after and end" {
  assert_true(parse_is_error("if true and | false then 1 | true then 2 end"))
}
