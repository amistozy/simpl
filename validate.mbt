///|
priv suberror StaticError {
  StaticErrorAt(String, SourceSpan)
} derive(Debug)

///|
fn validate(expr : Expr) -> Unit raise {
  validate_expr(expr, unknown_source_span())
}

///|
fn validate_expr(expr : Expr, span : SourceSpan) -> Unit raise {
  match expr {
    Located(expr_span, inner) => validate_expr(inner, expr_span)
    IntLit(_) | BoolLit(_) | StringLit(_) | NilLit | Var(_) => ()
    List(items) => items.each(item => validate_expr(item, span))
    Record(fields) => {
      validate_unique_record_fields(fields, span)
      fields.each(field => {
        let (_, value_expr) = field
        validate_expr(value_expr, span)
      })
    }
    Variant(_, value_expr) => validate_expr(value_expr, span)
    If(cases, else_expr) => {
      cases.each(arm => validate_if_cond_arm(arm, span))
      validate_expr(else_expr, span)
    }
    Let(pattern, value_expr, body) => {
      validate_pattern_bindings_unique(pattern, span)
      validate_expr(value_expr, span)
      validate_expr(body, span)
    }
    LetAnd(bindings, body) => {
      bindings.each(binding => {
        let (pattern, value_expr) = binding
        validate_pattern_bindings_unique(pattern, span)
        validate_expr(value_expr, span)
      })
      validate_expr(body, span)
    }
    LetRec(_, params, func_body, body) => {
      validate_params(params, span)
      validate_expr(func_body, span)
      validate_expr(body, span)
    }
    LetRecAnd(defs, body) => {
      defs.each(def => {
        let (_, params, func_body) = def
        validate_params(params, span)
        validate_expr(func_body, span)
      })
      validate_expr(body, span)
    }
    Lambda(params, body) => {
      validate_params(params, span)
      validate_expr(body, span)
    }
    Call(func_expr, arg_exprs) => {
      validate_unique_named_args(arg_exprs, span)
      validate_expr(func_expr, span)
      arg_exprs.each(arg => validate_call_arg_expr(arg, span))
    }
    Field(target, _) => validate_expr(target, span)
    Unary(_, one) => validate_expr(one, span)
    Binary(_, left, right) => {
      validate_expr(left, span)
      validate_expr(right, span)
    }
  }
}

///|
fn validate_if_cond_arm(arm : IfCondArm, span : SourceSpan) -> Unit raise {
  let IfCondArm(cond, guard_) = arm
  validate_expr(cond, span)
  validate_if_guard_static(guard_, span)
}

///|
fn validate_if_pattern_arm(arm : IfPatternArm, span : SourceSpan) -> Unit raise {
  let IfPatternArm(pattern, guard_) = arm
  validate_pattern_bindings_unique(pattern, span)
  validate_if_guard_static(guard_, span)
}

///|
fn validate_if_guard_static(guard_ : IfGuard, span : SourceSpan) -> Unit raise {
  match guard_ {
    IfThen(body) => validate_expr(body, span)
    IfAnd(arms) => arms.each(arm => validate_if_cond_arm(arm, span))
    IfIs(value_expr, arms) => {
      validate_expr(value_expr, span)
      arms.each(arm => validate_if_pattern_arm(arm, span))
    }
  }
}

///|
fn validate_call_arg_expr(arg : CallArg, span : SourceSpan) -> Unit raise {
  match arg {
    ArgPos(expr) => validate_expr(expr, span)
    ArgNamed(_, expr) => validate_expr(expr, span)
  }
}

///|
fn validate_unique_named_args(
  args : Array[CallArg],
  span : SourceSpan,
) -> Unit raise {
  let seen = Set::new()
  for arg in args {
    guard arg is ArgNamed(name, _) else {  }
    if !seen.add_and_check(name) {
      static_error_at("duplicate argument: \{name}", span)
    }
  }
}

///|
fn validate_params(params : Array[Param], span : SourceSpan) -> Unit raise {
  let seen_names = Set::new()
  for param in params; seen_default = false {
    let Param(pattern, default_expr, param_name) = param
    validate_pattern_bindings_unique(pattern, span)
    let has_default_expr = default_expr is Some(_)
    if seen_default && !has_default_expr {
      static_error_at("required params must appear before default params", span)
    }
    if param_name is Some(name) && !seen_names.add_and_check(name) {
      static_error_at("duplicate parameter: \{name}", span)
    }
    continue seen_default || has_default_expr
  }
}

///|
fn validate_pattern_bindings_unique(
  pattern : MatchPattern,
  span : SourceSpan,
) -> Unit raise {
  let seen = Set::new()
  let names = []
  core_pattern_binding_names(pattern, names)
  for name in names {
    if !seen.add_and_check(name) {
      static_error_at("duplicate pattern binding: \{name}", span)
    }
  }
}

///|
fn core_pattern_binding_names(
  pattern : MatchPattern,
  names : Array[String],
) -> Unit {
  match pattern {
    PBind(name) => if name != "_" { names.push(name) }
    PInt(_) | PBool(_) | PString(_) | PNil => ()
    POr(patterns) =>
      if patterns.length() != 0 {
        core_pattern_binding_names(patterns[0], names)
      }
    PVariant(_, inner) => core_pattern_binding_names(inner, names)
    PList(items) =>
      for item in items {
        core_pattern_binding_names(item, names)
      }
    PListRest(prefix, rest_name, suffix) => {
      for item in prefix {
        core_pattern_binding_names(item, names)
      }
      if rest_name != "_" {
        names.push(rest_name)
      }
      for item in suffix {
        core_pattern_binding_names(item, names)
      }
    }
    PRecord(fields) =>
      for field in fields {
        let (_, field_pattern) = field
        core_pattern_binding_names(field_pattern, names)
      }
  }
}

///|
fn validate_unique_record_fields(
  fields : Array[(String, Expr)],
  span : SourceSpan,
) -> Unit raise {
  let seen = Set::new()
  for field in fields {
    let (name, _) = field
    if !seen.add_and_check(name) {
      static_error_at("duplicate field: \{name}", span)
    }
  }
}

///|
fn[T] static_error_at(message : String, span : SourceSpan) -> T raise {
  raise StaticErrorAt(message, span)
}
