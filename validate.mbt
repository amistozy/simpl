///|
priv suberror StaticError {
  StaticErrorAt(String, SourceSpan)
} derive(Debug)

///|
fn validate(expr : Expr) -> Unit raise {
  validate_expr(expr, unknown_source_span(), [])
}

///|
fn validate_expr(
  expr : Expr,
  span : SourceSpan,
  bound_names : Array[String],
) -> Unit raise {
  match expr {
    Located(expr_span, inner) => validate_expr(inner, expr_span, bound_names)
    IntLit(_) | BoolLit(_) | StringLit(_) | NilLit => ()
    Var(name) =>
      if is_eta_placeholder_name(name) &&
        !array_contains_name(bound_names, name) {
        static_error_at(
          "underscore placeholder must appear inside 'fn' eta-expansion", span,
        )
      }
    List(items) =>
      items.each(item => {
        match item {
          ListOne(expr) | ListSpread(expr) =>
            validate_expr(expr, span, bound_names)
        }
      })
    Record(fields) => {
      validate_unique_record_fields(fields, span)
      fields.each(field => {
        let (_, value_expr) = field
        validate_expr(value_expr, span, bound_names)
      })
    }
    Variant(_, value_expr) => validate_expr(value_expr, span, bound_names)
    If(cases, else_expr) => {
      cases.each(arm => validate_if_cond_arm(arm, span, bound_names))
      validate_expr(else_expr, span, bound_names)
    }
    Let(pattern, value_expr, body) => {
      validate_pattern_bindings_unique(pattern, span)
      validate_expr(value_expr, span, bound_names)
      validate_expr(
        body,
        span,
        bound_names + pattern_binding_names_array(pattern),
      )
    }
    LetAnd(bindings, body) => {
      let binding_names = collect_binding_pattern_names(bindings, [], 0)
      bindings.each(binding => {
        let (pattern, value_expr) = binding
        validate_pattern_bindings_unique(pattern, span)
        validate_expr(value_expr, span, bound_names)
      })
      validate_expr(body, span, bound_names + binding_names)
    }
    LetRec(_, params, func_body, body) => {
      let func_bound_names = let_rec_scope_names(expr, [])
      validate_params(params, span)
      validate_expr(func_body, span, bound_names + func_bound_names)
      validate_expr(body, span, bound_names + func_bound_names)
    }
    LetRecAnd(defs, body) => {
      let rec_names = defs.map(def => {
        let (name, _, _) = def
        name
      })
      defs.each(def => {
        let (_, params, func_body) = def
        validate_params(params, span)
        validate_expr(
          func_body,
          span,
          bound_names + rec_names + collect_param_names(params, []),
        )
      })
      validate_expr(body, span, bound_names + rec_names)
    }
    Lambda(params, body) => {
      validate_params(params, span)
      validate_expr(body, span, bound_names + collect_param_names(params, []))
    }
    Call(func_expr, arg_exprs) => {
      validate_unique_named_args(arg_exprs, span)
      validate_expr(func_expr, span, bound_names)
      arg_exprs.each(arg => validate_call_arg_expr(arg, span, bound_names))
    }
    Field(target, _) => validate_expr(target, span, bound_names)
    Unary(_, one) => validate_expr(one, span, bound_names)
    Binary(_, left, right) => {
      validate_expr(left, span, bound_names)
      validate_expr(right, span, bound_names)
    }
  }
}

///|
fn validate_if_cond_arm(
  arm : IfCondArm,
  span : SourceSpan,
  bound_names : Array[String],
) -> Unit raise {
  let IfCondArm(cond, guard_) = arm
  validate_expr(cond, span, bound_names)
  validate_if_guard_static(guard_, span, bound_names)
}

///|
fn validate_if_pattern_arm(
  arm : IfPatternArm,
  span : SourceSpan,
  bound_names : Array[String],
) -> Unit raise {
  let IfPatternArm(pattern, guard_) = arm
  validate_pattern_bindings_unique(pattern, span)
  validate_if_guard_static(
    guard_,
    span,
    bound_names + pattern_binding_names_array(pattern),
  )
}

///|
fn validate_if_guard_static(
  guard_ : IfGuard,
  span : SourceSpan,
  bound_names : Array[String],
) -> Unit raise {
  match guard_ {
    IfThen(body) => validate_expr(body, span, bound_names)
    IfAnd(arms) =>
      arms.each(arm => validate_if_cond_arm(arm, span, bound_names))
    IfIs(value_expr, arms) => {
      validate_expr(value_expr, span, bound_names)
      arms.each(arm => validate_if_pattern_arm(arm, span, bound_names))
    }
  }
}

///|
fn validate_call_arg_expr(
  arg : CallArg,
  span : SourceSpan,
  bound_names : Array[String],
) -> Unit raise {
  match arg {
    ArgPos(expr) => validate_expr(expr, span, bound_names)
    ArgNamed(_, expr) => validate_expr(expr, span, bound_names)
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
  for name in pattern_binding_names_array(pattern) {
    if !seen.add_and_check(name) {
      static_error_at("duplicate pattern binding: \{name}", span)
    }
  }
}

///|
fn pattern_binding_names_array(pattern : MatchPattern) -> Array[String] {
  let names = []
  core_pattern_binding_names(pattern, names)
  names
}

///|
fn core_pattern_binding_names(
  pattern : MatchPattern,
  names : Array[String],
) -> Unit {
  match pattern {
    PBind(name) => if name != "_" { names.push(name) }
    PInt(_) | PBool(_) | PString(_) | PNil => ()
    PAs(inner, name) => {
      core_pattern_binding_names(inner, names)
      if name != "_" {
        names.push(name)
      }
    }
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
fn collect_binding_pattern_names(
  bindings : Array[(MatchPattern, Expr)],
  acc : Array[String],
  i : Int,
) -> Array[String] {
  guard i < bindings.length() else { acc }
  let (pattern, _) = bindings[i]
  collect_binding_pattern_names(
    bindings,
    acc + pattern_binding_names_array(pattern),
    i + 1,
  )
}

///|
fn collect_param_names(
  params : Array[Param],
  acc : Array[String],
) -> Array[String] {
  params.fold(init=acc, (acc, param) => {
    let Param(pattern, _, _) = param
    acc + pattern_binding_names_array(pattern)
  })
}

///|
fn let_rec_scope_names(expr : Expr, acc : Array[String]) -> Array[String] {
  match expr {
    LetRec(name, params, _, _) => acc + [name] + collect_param_names(params, [])
    _ => acc
  }
}

///|
fn is_eta_placeholder_name(name : String) -> Bool {
  name.has_prefix(" __eta")
}

///|
fn array_contains_name(items : Array[String], target : String) -> Bool {
  items.contains(target)
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
