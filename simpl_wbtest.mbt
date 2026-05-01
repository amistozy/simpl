///|

///|
fn expr_is_located_int(expr : Expr, expected : Int) -> Bool {
  match expr {
    Located(_, IntLit(value)) => value == expected
    IntLit(value) => value == expected
    _ => false
  }
}

///|
fn expr_is_located_var(expr : Expr, expected : String) -> Bool {
  match expr {
    Located(_, Var(name)) => name == expected
    Var(name) => name == expected
    _ => false
  }
}

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
test "parser lowers f x into a one-arg call" {
  match parse("f x") {
    SLocated(
      _,
      SCall(SLocated(_, SVar("f")), [SArgPos(SLocated(_, SVar("x")))])
    ) => assert_true(true)
    _ => assert_true(false)
  }
}

///|
test "parser appends trailing arg to direct call" {
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
test "desugar turns trailing arg after call into chained call" {
  let expr = desugar(parse("(f 1) 3"))
  let env = initial_env().add(
    "f",
    VClosure(
      [Param(PBind("x"), None, Some("x"))],
      Lambda(
        [Param(PBind("y"), None, Some("y"))],
        Binary(Add, Var("x"), Var("y")),
      ),
      initial_env(),
    ),
  )
  assert_true(
    try eval_with_env(expr, env) catch {
      _ => false
    } noraise {
      VInt(v) => v == 4
      _ => false
    },
  )
}

///|
test "desugar keeps parser-built appended call shape" {
  match desugar(parse("f(1; 2) 3")) {
    Located(_, Call(callee, [ArgPos(arg1), ArgPos(arg2), ArgPos(arg3)])) =>
      assert_true(
        expr_is_located_var(callee, "f") &&
        expr_is_located_int(arg1, 1) &&
        expr_is_located_int(arg2, 2) &&
        expr_is_located_int(arg3, 3),
      )
    _ => assert_true(false)
  }
}

///|
test "parser turns :(...) into ordinary grouped call arg" {
  assert_eq(
    surface_expr_pretty(parse("say: (1 + 2) * 3")),
    "say(((1 + 2) * 3))",
  )
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
test "parser passes trailing lambda as one call arg" {
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
test "parser preserves unary tilde in surface ast" {
  match parse("~1") {
    SLocated(_, SUnary(Neg, SLocated(_, SIntLit(1)))) => assert_true(true)
    _ => assert_true(false)
  }
}

///|
test "parser preserves negative int literal in surface ast" {
  match parse("-42") {
    SLocated(_, SIntLit(-42)) => assert_true(true)
    _ => assert_true(false)
  }
}

///|
test "negative literal can be the argument of trailing application" {
  match parse("1-42") {
    SLocated(
      _,
      SCall(SLocated(_, SIntLit(1)), [SArgPos(SLocated(_, SIntLit(-42)))])
    ) => assert_true(true)
    _ => assert_true(false)
  }
}

///|
test "parser preserves with(params) surface form" {
  match parse("with(v) = use(41); v + 1") {
    SLocated(
      _,
      SWith(
        [SParam(SPBind("v"), None)],
        SLocated(
          _,
          SCall(SLocated(_, SVar("use")), [SArgPos(SLocated(_, SIntLit(41)))])
        ),
        SLocated(
          _,
          SBinary(Add, SLocated(_, SVar("v")), SLocated(_, SIntLit(1)))
        )
      )
    ) => assert_true(true)
    _ => assert_true(false)
  }
}

///|
test "parser preserves zero-parameter with surface form" {
  match parse("with run(); 42") {
    SLocated(
      _,
      SWith(
        [],
        SLocated(_, SCall(SLocated(_, SVar("run")), [])),
        SLocated(_, SIntLit(42))
      )
    ) => assert_true(true)
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
test "parser preserves as-pattern before desugar" {
  match parse("let #Ok(x) as whole = #Ok(1); whole") {
    SLocated(_, SLet(SPAs(SPVariant("Ok", SPBind("x")), "whole"), _, _)) =>
      assert_true(true)
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
test "desugar lowers as-pattern to core as-pattern" {
  match desugar_pattern(SPAs(SPVariant("Ok", SPBind("x")), "whole")) {
    PAs(PVariant("Ok", PBind("x")), "whole") => assert_true(true)
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
