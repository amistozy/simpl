///|
fn desugar(expr : SurfaceExpr) -> Expr {
  match expr {
    SLocated(span, inner) => Located(span, desugar(inner))
    SIntLit(v) => IntLit(v)
    SBoolLit(v) => BoolLit(v)
    SStringLit(v) => StringLit(v)
    SNilLit => NilLit
    SVar(name) => Var(name)
    SList(items) => List(items.map(item => desugar(item)))
    SRecord(fields) => Record(fields.map(field => desugar_record_field(field)))
    SVariant(tag, value_expr) => Variant(tag, desugar(value_expr))
    SIf(cases, else_expr) =>
      If(cases.map(case => desugar_if_cond_arm(case)), desugar(else_expr))
    SLet(pattern, value_expr, body) =>
      Let(desugar_pattern(pattern), desugar(value_expr), desugar(body))
    SLetAnd(bindings, body) =>
      LetAnd(
        bindings.map(binding => desugar_let_binding(binding)),
        desugar(body),
      )
    SDo(value_expr, body) => Let(PBind("_"), desugar(value_expr), desugar(body))
    SLetFun(name, params, func_body, body) =>
      Let(
        PBind(name),
        Lambda(params.map(param => desugar_param(param)), desugar(func_body)),
        desugar(body),
      )
    SLetRec(name, params, func_body, body) =>
      LetRec(
        name,
        params.map(param => desugar_param(param)),
        desugar(func_body),
        desugar(body),
      )
    SLetRecAnd(defs, body) =>
      LetRecAnd(defs.map(def => desugar_let_rec_def(def)), desugar(body))
    SWith(params, target_expr, body) =>
      append_trailing_arg_core(
        desugar(target_expr),
        Lambda(params.map(param => desugar_param(param)), desugar(body)),
      )
    STrailingCall(func_expr, arg_expr) =>
      append_trailing_arg_core(desugar(func_expr), desugar(arg_expr))
    SLambda(params, body) =>
      Lambda(params.map(param => desugar_param(param)), desugar(body))
    SCall(func_expr, arg_exprs) =>
      Call(desugar(func_expr), arg_exprs.map(arg => desugar_call_arg(arg)))
    SField(target, name) => Field(desugar(target), name)
    SUnary(op, one) => Unary(op, desugar(one))
    SBinary(op, left, right) => Binary(op, desugar(left), desugar(right))
  }
}

///|
fn append_trailing_arg_core(target_expr : Expr, arg_expr : Expr) -> Expr {
  match target_expr {
    Located(span, inner) =>
      Located(span, append_trailing_arg_core(inner, arg_expr))
    Call(func_expr, args) => Call(func_expr, args + [ArgPos(arg_expr)])
    _ => Call(target_expr, [ArgPos(arg_expr)])
  }
}

///|
fn desugar_if_cond_arm(surface_arm : SurfaceIfCondArm) -> IfCondArm {
  match surface_arm {
    SIfCondArm(cond, arm_guard) =>
      IfCondArm(desugar(cond), desugar_if_guard(arm_guard))
  }
}

///|
fn desugar_if_pattern_arm(surface_arm : SurfaceIfPatternArm) -> IfPatternArm {
  match surface_arm {
    SIfPatternArm(pattern, arm_guard) =>
      IfPatternArm(desugar_pattern(pattern), desugar_if_guard(arm_guard))
  }
}

///|
fn desugar_if_guard(surface_guard : SurfaceIfGuard) -> IfGuard {
  match surface_guard {
    SIfThen(body) => IfThen(desugar(body))
    SIfAnd(arms) => IfAnd(arms.map(arm => desugar_if_cond_arm(arm)))
    SIfIs(value_expr, arms) =>
      IfIs(desugar(value_expr), arms.map(arm => desugar_if_pattern_arm(arm)))
  }
}

///|
fn desugar_record_field(field : SurfaceRecordField) -> (String, Expr) {
  match field {
    SRecordField(name, value_expr) => (name, desugar(value_expr))
    SRecordShorthand(name) => (name, Var(name))
  }
}

///|
fn desugar_pattern(pattern : SurfacePattern) -> MatchPattern {
  match pattern {
    SPBind(name) => PBind(name)
    SPInt(value) => PInt(value)
    SPBool(value) => PBool(value)
    SPString(value) => PString(value)
    SPNil => PNil
    SPOr(patterns) => POr(patterns.map(item => desugar_pattern(item)))
    SPVariant(tag, inner) => PVariant(tag, desugar_pattern(inner))
    SPList(items) => PList(items.map(item => desugar_pattern(item)))
    SPListRest(prefix, rest_name, suffix) =>
      PListRest(
        prefix.map(item => desugar_pattern(item)),
        rest_name,
        suffix.map(item => desugar_pattern(item)),
      )
    SPRecord(fields) =>
      PRecord(fields.map(field => desugar_record_pattern_field(field)))
  }
}

///|
fn desugar_param(param : SurfaceParam) -> Param {
  match param {
    SParam(pattern, default_expr) => {
      let core_pattern = desugar_pattern(pattern)
      let core_default = match default_expr {
        Some(expr) => Some(desugar(expr))
        None => None
      }
      let name = match core_pattern {
        PBind(n) => Some(n)
        _ => None
      }
      Param(core_pattern, core_default, name)
    }
  }
}

///|
fn desugar_call_arg(arg : SurfaceCallArg) -> CallArg {
  match arg {
    SArgPos(expr) => ArgPos(desugar(expr))
    SArgNamed(name, expr) => ArgNamed(name, desugar(expr))
  }
}

///|
fn desugar_record_pattern_field(
  field : SurfaceRecordPatternField,
) -> (String, MatchPattern) {
  match field {
    SPRecordField(name, pattern) => (name, desugar_pattern(pattern))
    SPRecordShorthand(name) => (name, PBind(name))
  }
}

///|
fn desugar_let_binding(
  binding : (SurfacePattern, SurfaceExpr),
) -> (MatchPattern, Expr) {
  let (pattern, value_expr) = binding
  (desugar_pattern(pattern), desugar(value_expr))
}

///|
fn desugar_let_rec_def(
  def : (String, Array[SurfaceParam], SurfaceExpr),
) -> (String, Array[Param], Expr) {
  let (name, params, func_body) = def
  (name, params.map(param => desugar_param(param)), desugar(func_body))
}
