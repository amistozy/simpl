///|
fn desugar(expr : SurfaceExpr) -> Expr {
  let (core_expr, _, _) = desugar_expr_with_placeholders(expr, 0)
  core_expr
}

///|
fn append_call_arg_core(target_expr : Expr, arg_expr : Expr) -> Expr {
  match target_expr {
    Located(span, inner) => Located(span, append_call_arg_core(inner, arg_expr))
    Call(func_expr, args) => Call(func_expr, args + [ArgPos(arg_expr)])
    _ => Call(target_expr, [ArgPos(arg_expr)])
  }
}

///|
fn desugar_expr_with_placeholders(
  expr : SurfaceExpr,
  next_placeholder_id : Int,
) -> (Expr, Array[String], Int) {
  match expr {
    SLocated(span, inner) => {
      let (core_expr, names, next_id) = desugar_expr_with_placeholders(
        inner,
        next_placeholder_id,
      )
      (Located(span, core_expr), names, next_id)
    }
    SIntLit(v) => (IntLit(v), [], next_placeholder_id)
    SBoolLit(v) => (BoolLit(v), [], next_placeholder_id)
    SStringLit(v) => (StringLit(v), [], next_placeholder_id)
    SNilLit => (NilLit, [], next_placeholder_id)
    SUnderscore => {
      let name = eta_placeholder_name(next_placeholder_id)
      (Var(name), [name], next_placeholder_id + 1)
    }
    SVar(name) => (Var(name), [], next_placeholder_id)
    SList(items) => {
      let (items_core, names, next_id) = desugar_expr_list_with_placeholders(
        items,
        next_placeholder_id,
        [],
        [],
        0,
      )
      (List(items_core), names, next_id)
    }
    SRecord(fields) => {
      let (fields_core, names, next_id) = desugar_record_fields_with_placeholders(
        fields,
        next_placeholder_id,
        [],
        [],
        0,
      )
      (Record(fields_core), names, next_id)
    }
    SVariant(tag, value_expr) => {
      let (value_core, names, next_id) = desugar_expr_with_placeholders(
        value_expr,
        next_placeholder_id,
      )
      (Variant(tag, value_core), names, next_id)
    }
    SIf(cases, else_expr) => {
      let (cases_core, case_names, next_after_cases) =
        desugar_if_cond_arms_with_placeholders(cases, next_placeholder_id, [], [], 0)
      let (else_core, else_names, next_id) = desugar_expr_with_placeholders(
        else_expr,
        next_after_cases,
      )
      (If(cases_core, else_core), case_names + else_names, next_id)
    }
    SLet(pattern, value_expr, body) => {
      let (value_core, value_names, next_after_value) =
        desugar_expr_with_placeholders(value_expr, next_placeholder_id)
      let (body_core, body_names, next_id) = desugar_expr_with_placeholders(
        body,
        next_after_value,
      )
      (Let(desugar_pattern(pattern), value_core, body_core), value_names + body_names, next_id)
    }
    SLetAnd(bindings, body) => {
      let (bindings_core, binding_names, next_after_bindings) =
        desugar_let_bindings_with_placeholders(bindings, next_placeholder_id, [], [], 0)
      let (body_core, body_names, next_id) = desugar_expr_with_placeholders(
        body,
        next_after_bindings,
      )
      (LetAnd(bindings_core, body_core), binding_names + body_names, next_id)
    }
    SDo(value_expr, body) => {
      let (value_core, value_names, next_after_value) =
        desugar_expr_with_placeholders(value_expr, next_placeholder_id)
      let (body_core, body_names, next_id) = desugar_expr_with_placeholders(
        body,
        next_after_value,
      )
      (Let(PBind("_"), value_core, body_core), value_names + body_names, next_id)
    }
    SLetFun(name, params, func_body, body) => {
      let (func_body_core, func_names, next_after_func) =
        desugar_expr_with_placeholders(func_body, next_placeholder_id)
      let (body_core, body_names, next_id) = desugar_expr_with_placeholders(
        body,
        next_after_func,
      )
      (
        Let(
          PBind(name),
          Lambda(params.map(param => desugar_param(param)), func_body_core),
          body_core,
        ),
        func_names + body_names,
        next_id,
      )
    }
    SLetRec(name, params, func_body, body) => {
      let (func_body_core, func_names, next_after_func) =
        desugar_expr_with_placeholders(func_body, next_placeholder_id)
      let (body_core, body_names, next_id) = desugar_expr_with_placeholders(
        body,
        next_after_func,
      )
      (
        LetRec(
          name,
          params.map(param => desugar_param(param)),
          func_body_core,
          body_core,
        ),
        func_names + body_names,
        next_id,
      )
    }
    SLetRecAnd(defs, body) => {
      let (defs_core, def_names, next_after_defs) =
        desugar_let_rec_defs_with_placeholders(defs, next_placeholder_id, [], [], 0)
      let (body_core, body_names, next_id) = desugar_expr_with_placeholders(
        body,
        next_after_defs,
      )
      (LetRecAnd(defs_core, body_core), def_names + body_names, next_id)
    }
    SWith(params, target_expr, body) => {
      let (target_core, target_names, next_after_target) =
        desugar_expr_with_placeholders(target_expr, next_placeholder_id)
      let (body_core, body_names, next_id) = desugar_expr_with_placeholders(
        body,
        next_after_target,
      )
      (
        append_call_arg_core(
          target_core,
          Lambda(params.map(param => desugar_param(param)), body_core),
        ),
        target_names + body_names,
        next_id,
      )
    }
    SLambda(params, body) => {
      let (body_core, names, next_id) = desugar_expr_with_placeholders(
        body,
        next_placeholder_id,
      )
      (Lambda(params.map(param => desugar_param(param)), body_core), names, next_id)
    }
    SCall(func_expr, arg_exprs) =>
      desugar_call_with_placeholders(func_expr, arg_exprs, next_placeholder_id)
    SField(target, name) => {
      let (target_core, names, next_id) = desugar_expr_with_placeholders(
        target,
        next_placeholder_id,
      )
      (Field(target_core, name), names, next_id)
    }
    SUnary(op, one) => {
      let (one_core, names, next_id) = desugar_expr_with_placeholders(
        one,
        next_placeholder_id,
      )
      (Unary(op, one_core), names, next_id)
    }
    SBinary(op, left, right) => {
      let (left_core, left_names, next_after_left) =
        desugar_expr_with_placeholders(left, next_placeholder_id)
      let (right_core, right_names, next_id) = desugar_expr_with_placeholders(
        right,
        next_after_left,
      )
      (Binary(op, left_core, right_core), left_names + right_names, next_id)
    }
  }
}

///|
fn desugar_call_with_placeholders(
  func_expr : SurfaceExpr,
  arg_exprs : Array[SurfaceCallArg],
  next_placeholder_id : Int,
) -> (Expr, Array[String], Int) {
  let (func_core, func_names, next_after_func) = desugar_expr_with_placeholders(
    func_expr,
    next_placeholder_id,
  )
  if arg_exprs.length() == 0 {
    return (Call(func_core, []), func_names, next_after_func)
  }
  desugar_call_args_with_placeholders(
    arg_exprs,
    next_after_func,
    func_core,
    [],
    func_names,
    0,
  )
}

///|
fn finalize_call_chunk(func_expr : Expr, args : Array[CallArg]) -> Expr {
  if args.length() == 0 {
    func_expr
  } else {
    Call(func_expr, args)
  }
}

///|
fn desugar_call_args_with_placeholders(
  args : Array[SurfaceCallArg],
  next_placeholder_id : Int,
  current_expr : Expr,
  pending_args : Array[CallArg],
  bubbled_names : Array[String],
  i : Int,
) -> (Expr, Array[String], Int) {
  guard i < args.length() else {
    (finalize_call_chunk(current_expr, pending_args), bubbled_names, next_placeholder_id)
  }
  match args[i] {
    SArgPos(arg_expr) => {
      let (arg_core, arg_names, next_id) = desugar_expr_with_placeholders(
        arg_expr,
        next_placeholder_id,
      )
      let next_arg = if arg_names.length() != 0 &&
        !surface_expr_is_bare_underscore(arg_expr) {
        ArgPos(wrap_eta_lambda(arg_core, arg_names))
      } else {
        ArgPos(arg_core)
      }
      let next_names = if arg_names.length() != 0 &&
        !surface_expr_is_bare_underscore(arg_expr) {
        bubbled_names
      } else {
        bubbled_names + arg_names
      }
      desugar_call_args_with_placeholders(
        args,
        next_id,
        current_expr,
        pending_args + [next_arg],
        next_names,
        i + 1,
      )
    }
    SArgNamed(name, arg_expr) => {
      let (arg_core, arg_names, next_id) = desugar_expr_with_placeholders(
        arg_expr,
        next_placeholder_id,
      )
      let next_arg = if arg_names.length() != 0 &&
        !surface_expr_is_bare_underscore(arg_expr) {
        ArgNamed(name, wrap_eta_lambda(arg_core, arg_names))
      } else {
        ArgNamed(name, arg_core)
      }
      let next_names = if arg_names.length() != 0 &&
        !surface_expr_is_bare_underscore(arg_expr) {
        bubbled_names
      } else {
        bubbled_names + arg_names
      }
      desugar_call_args_with_placeholders(
        args,
        next_id,
        current_expr,
        pending_args + [next_arg],
        next_names,
        i + 1,
      )
    }
    STrailingArgPos(arg_expr) => {
      let (arg_core, arg_names, next_id) = desugar_expr_with_placeholders(
        arg_expr,
        next_placeholder_id,
      )
      let next_expr = if pending_args.length() == 0 {
        Call(current_expr, [ArgPos(arg_core)])
      } else {
        finalize_call_chunk(current_expr, pending_args + [ArgPos(arg_core)])
      }
      desugar_call_args_with_placeholders(
        args,
        next_id,
        next_expr,
        [],
        bubbled_names + arg_names,
        i + 1,
      )
    }
  }
}

///|
fn wrap_eta_lambda(body : Expr, names : Array[String]) -> Expr {
  Lambda(names.map(name => Param(PBind(name), None, Some(name))), body)
}

///|
fn eta_placeholder_name(id : Int) -> String {
  " __eta\{id}"
}

///|
fn surface_expr_is_bare_underscore(expr : SurfaceExpr) -> Bool {
  match expr {
    SLocated(_, inner) => surface_expr_is_bare_underscore(inner)
    SUnderscore => true
    _ => false
  }
}

///|
fn desugar_expr_list_with_placeholders(
  exprs : Array[SurfaceExpr],
  next_placeholder_id : Int,
  acc : Array[Expr],
  names : Array[String],
  i : Int,
) -> (Array[Expr], Array[String], Int) {
  guard i < exprs.length() else { (acc, names, next_placeholder_id) }
  let (head_core, head_names, next_id) = desugar_expr_with_placeholders(
    exprs[i],
    next_placeholder_id,
  )
  desugar_expr_list_with_placeholders(
    exprs,
    next_id,
    acc + [head_core],
    names + head_names,
    i + 1,
  )
}

///|
fn desugar_record_fields_with_placeholders(
  fields : Array[SurfaceRecordField],
  next_placeholder_id : Int,
  acc : Array[(String, Expr)],
  names : Array[String],
  i : Int,
) -> (Array[(String, Expr)], Array[String], Int) {
  guard i < fields.length() else { (acc, names, next_placeholder_id) }
  let (name, value_expr) = match fields[i] {
    SRecordField(field_name, expr) => (field_name, expr)
    SRecordShorthand(field_name) => (field_name, SVar(field_name))
  }
  let (value_core, value_names, next_id) = desugar_expr_with_placeholders(
    value_expr,
    next_placeholder_id,
  )
  desugar_record_fields_with_placeholders(
    fields,
    next_id,
    acc + [(name, value_core)],
    names + value_names,
    i + 1,
  )
}

///|
fn desugar_if_cond_arms_with_placeholders(
  arms : Array[SurfaceIfCondArm],
  next_placeholder_id : Int,
  acc : Array[IfCondArm],
  names : Array[String],
  i : Int,
) -> (Array[IfCondArm], Array[String], Int) {
  guard i < arms.length() else { (acc, names, next_placeholder_id) }
  let (head_core, head_names, next_id) = desugar_if_cond_arm_with_placeholders(
    arms[i],
    next_placeholder_id,
  )
  desugar_if_cond_arms_with_placeholders(
    arms,
    next_id,
    acc + [head_core],
    names + head_names,
    i + 1,
  )
}

///|
fn desugar_if_cond_arm_with_placeholders(
  surface_arm : SurfaceIfCondArm,
  next_placeholder_id : Int,
) -> (IfCondArm, Array[String], Int) {
  match surface_arm {
    SIfCondArm(cond, arm_guard) => {
      let (cond_core, cond_names, next_after_cond) =
        desugar_expr_with_placeholders(cond, next_placeholder_id)
      let (guard_core, guard_names, next_id) =
        desugar_if_guard_with_placeholders(arm_guard, next_after_cond)
      (IfCondArm(cond_core, guard_core), cond_names + guard_names, next_id)
    }
  }
}

///|
fn desugar_if_pattern_arm_with_placeholders(
  surface_arm : SurfaceIfPatternArm,
  next_placeholder_id : Int,
) -> (IfPatternArm, Array[String], Int) {
  match surface_arm {
    SIfPatternArm(pattern, arm_guard) => {
      let (guard_core, guard_names, next_id) =
        desugar_if_guard_with_placeholders(arm_guard, next_placeholder_id)
      (IfPatternArm(desugar_pattern(pattern), guard_core), guard_names, next_id)
    }
  }
}

///|
fn desugar_if_guard_with_placeholders(
  surface_guard : SurfaceIfGuard,
  next_placeholder_id : Int,
) -> (IfGuard, Array[String], Int) {
  match surface_guard {
    SIfThen(body) => {
      let (body_core, names, next_id) = desugar_expr_with_placeholders(
        body,
        next_placeholder_id,
      )
      (IfThen(body_core), names, next_id)
    }
    SIfAnd(arms) => {
      let (arms_core, names, next_id) = desugar_if_cond_arms_with_placeholders(
        arms,
        next_placeholder_id,
        [],
        [],
        0,
      )
      (IfAnd(arms_core), names, next_id)
    }
    SIfIs(value_expr, arms) => {
      let (value_core, value_names, next_after_value) =
        desugar_expr_with_placeholders(value_expr, next_placeholder_id)
      let (arms_core, arm_names, next_id) =
        desugar_if_pattern_arms_with_placeholders(arms, next_after_value, [], [], 0)
      (IfIs(value_core, arms_core), value_names + arm_names, next_id)
    }
  }
}

///|
fn desugar_if_pattern_arms_with_placeholders(
  arms : Array[SurfaceIfPatternArm],
  next_placeholder_id : Int,
  acc : Array[IfPatternArm],
  names : Array[String],
  i : Int,
) -> (Array[IfPatternArm], Array[String], Int) {
  guard i < arms.length() else { (acc, names, next_placeholder_id) }
  let (head_core, head_names, next_id) =
    desugar_if_pattern_arm_with_placeholders(arms[i], next_placeholder_id)
  desugar_if_pattern_arms_with_placeholders(
    arms,
    next_id,
    acc + [head_core],
    names + head_names,
    i + 1,
  )
}

///|
fn desugar_let_bindings_with_placeholders(
  bindings : Array[(SurfacePattern, SurfaceExpr)],
  next_placeholder_id : Int,
  acc : Array[(MatchPattern, Expr)],
  names : Array[String],
  i : Int,
) -> (Array[(MatchPattern, Expr)], Array[String], Int) {
  guard i < bindings.length() else { (acc, names, next_placeholder_id) }
  let (pattern, value_expr) = bindings[i]
  let (value_core, value_names, next_id) = desugar_expr_with_placeholders(
    value_expr,
    next_placeholder_id,
  )
  desugar_let_bindings_with_placeholders(
    bindings,
    next_id,
    acc + [(desugar_pattern(pattern), value_core)],
    names + value_names,
    i + 1,
  )
}

///|
fn desugar_let_rec_defs_with_placeholders(
  defs : Array[(String, Array[SurfaceParam], SurfaceExpr)],
  next_placeholder_id : Int,
  acc : Array[(String, Array[Param], Expr)],
  names : Array[String],
  i : Int,
) -> (Array[(String, Array[Param], Expr)], Array[String], Int) {
  guard i < defs.length() else { (acc, names, next_placeholder_id) }
  let (name, params, func_body) = defs[i]
  let (func_body_core, func_names, next_id) = desugar_expr_with_placeholders(
    func_body,
    next_placeholder_id,
  )
  desugar_let_rec_defs_with_placeholders(
    defs,
    next_id,
    acc + [(name, params.map(param => desugar_param(param)), func_body_core)],
    names + func_names,
    i + 1,
  )
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

fn desugar_pattern(pattern : SurfacePattern) -> MatchPattern {
  match pattern {
    SPBind(name) => PBind(name)
    SPInt(value) => PInt(value)
    SPBool(value) => PBool(value)
    SPString(value) => PString(value)
    SPNil => PNil
    SPAs(inner, name) => PAs(desugar_pattern(inner), name)
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
fn desugar_record_pattern_field(
  field : SurfaceRecordPatternField,
) -> (String, MatchPattern) {
  match field {
    SPRecordField(name, pattern) => (name, desugar_pattern(pattern))
    SPRecordShorthand(name) => (name, PBind(name))
  }
}
