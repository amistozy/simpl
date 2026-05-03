///|
priv suberror EvalError {
  RuntimeErrorAt(String, SourceSpan)
} derive(Debug)

///|
fn eval(expr : Expr) -> Value raise {
  eval_with_env(expr, initial_env())
}

///|
fn eval_with_env(expr : Expr, env : Env) -> Value raise {
  match expr {
    Located(span, inner) =>
      eval_with_env(inner, env) catch {
        RuntimeErrorAt(message, inner_span) =>
          raise RuntimeErrorAt(
            message,
            if inner_span == unknown_source_span() {
              span
            } else {
              inner_span
            },
          )
        _ => raise RuntimeErrorAt("unknown runtime error", span)
      }
    IntLit(v) => VInt(v)
    StringLit(v) => VString(v)
    List(items) => VList(eval_list_items(items, env))
    Var(name) => lookup(env, name)
    If(cases, else_expr) => eval_if_cond_arms(cases, else_expr, env, 0)
    Let(pattern, value_expr, body) => {
      let v = eval_with_env(value_expr, env)
      let bound_env = bind_pattern(pattern, v, env)
      eval_with_env(body, bound_env)
    }
    LetAnd(bindings, body) => {
      let bound_env = eval_let_and_bindings(bindings, env)
      eval_with_env(body, bound_env)
    }
    LetRec(name, params, func_body, body) => {
      let rec_env = build_rec_env([(name, params, func_body)], env)
      eval_with_env(body, rec_env)
    }
    LetRecAnd(defs, body) => {
      let rec_env = build_rec_env(defs, env)
      eval_with_env(body, rec_env)
    }
    Lambda(params, body) => VClosure(params, body, env)
    Call(func_expr, arg_exprs) => {
      guard as_ufcs_field_callee(func_expr) is Some((target, name)) else {
        let func_value = eval_with_env(func_expr, env)
        let args = eval_call_args(arg_exprs, env)
        return apply(func_value, args)
      }
      let target_value = eval_with_env(target, env)
      let args = eval_call_args(arg_exprs, env)
      eval_field_call_or_ufcs(target_value, name, args, env)
    }
    Field(target, name) => {
      let target_value = eval_with_env(target, env)
      eval_field_value_or_ufcs(target_value, name, env)
    }
  }
}

///|
fn eval_condition(cond : Expr, env : Env) -> Bool raise {
  truthy(eval_with_env(cond, env))
}

///|
fn eval_if_cond_arms(
  arms : Array[IfCondArm],
  else_expr : Expr,
  env : Env,
  i : Int,
) -> Value raise {
  guard eval_if_cond_arms_with_fallback(arms, Some(else_expr), env, i)
    is Some(result) else {
    eval_with_env(else_expr, env)
  }
  result
}

///|
fn eval_if_cond_arms_with_fallback(
  arms : Array[IfCondArm],
  fallback : Expr?,
  env : Env,
  i : Int,
) -> Value? raise {
  guard i < arms.length() else {
    fallback.map(default_expr => eval_with_env(default_expr, env))
  }
  let IfCondArm(cond, arm_guard) = arms[i]
  let passes = eval_condition(cond, env)
  guard passes else {
    eval_if_cond_arms_with_fallback(arms, fallback, env, i + 1)
  }
  guard eval_if_guard(arm_guard, env) is Some(result) else {
    eval_if_cond_arms_with_fallback(arms, fallback, env, i + 1)
  }
  Some(result)
}

///|
fn eval_let_and_bindings(
  bindings : Array[(MatchPattern, Expr)],
  env : Env,
) -> Env raise {
  bindings
  .map(binding => {
    let (pattern, value_expr) = binding
    (pattern, eval_with_env(value_expr, env))
  })
  .fold(init=env, (env, evaluated) => {
    let (pattern, value) = evaluated
    bind_pattern(pattern, value, env)
  })
}

///|
/// Helpers: list and argument evaluation
fn eval_list_items(items : Array[ListItem], env : Env) -> Array[Value] raise {
  let values = []
  for item in items {
    match item {
      ListOne(expr) => values.push(eval_with_env(expr, env))
      ListSpread(expr) =>
        match eval_with_env(expr, env) {
          VList(spread_items) => values.append(spread_items)
          value => type_error_unary("list spread", "List", value)
        }
    }
  }
  values
}

///|
fn eval_call_args(
  args : Array[CallArg],
  env : Env,
) -> Array[EvaluatedCallArg] raise {
  args.map(arg => eval_call_arg(arg, env))
}

///|
fn eval_call_arg(arg : CallArg, env : Env) -> EvaluatedCallArg raise {
  match arg {
    ArgPos(expr) => EArgPos(eval_with_env(expr, env))
    ArgNamed(name, expr) => EArgNamed(name, eval_with_env(expr, env))
  }
}

///|
fn as_ufcs_field_callee(expr : Expr) -> (Expr, String)? {
  match expr {
    Field(target, name) => Some((target, name))
    Located(_, inner) => as_ufcs_field_callee(inner)
    _ => None
  }
}

///|
fn eval_field_value_or_ufcs(
  target_value : Value,
  name : String,
  env : Env,
) -> Value raise {
  guard target_value is VRecord(fields) else {
    apply_ufcs(name, target_value, [], env)
  }
  guard fields.get(name) is Some(value) else {
    guard lookup_function(env, name) is Some(func_value) else {
      missing_field_error(name, target_value)
    }
    apply(func_value, [EArgPos(target_value)])
  }
  value
}

///|
fn eval_field_call_or_ufcs(
  target_value : Value,
  name : String,
  args : Array[EvaluatedCallArg],
  env : Env,
) -> Value raise {
  guard target_value is VRecord(fields) else {
    apply_ufcs(name, target_value, args, env)
  }
  guard fields.get(name) is Some(value) else {
    guard lookup_function(env, name) is Some(func_value) else {
      missing_field_error(name, target_value)
    }
    apply(func_value, [EArgPos(target_value)] + args)
  }
  apply(value, args)
}

///|
fn apply_ufcs(
  name : String,
  target_value : Value,
  args : Array[EvaluatedCallArg],
  env : Env,
) -> Value raise {
  guard lookup_function(env, name) is Some(func_value) else {
    missing_function_error(name)
  }
  apply(func_value, [EArgPos(target_value)] + args)
}

///|
fn eval_if_guard(arm_guard : IfGuard, env : Env) -> Value? raise {
  match arm_guard {
    IfThen(body) => Some(eval_with_env(body, env))
    IfAnd(arms) => eval_if_cond_arms_with_fallback(arms, None, env, 0)
    IfIs(value_expr, arms) => {
      let value = eval_with_env(value_expr, env)
      eval_if_pattern_arms_with_fallback(value, arms, None, env)
    }
  }
}

///|
fn unknown_source_span() -> SourceSpan {
  ((0, 1, 1), (0, 1, 1))
}

///|
fn[T] runtime_error(message : String) -> T raise {
  raise RuntimeErrorAt(message, unknown_source_span())
}

///|
fn[T] undefined_variable_error(name : String) -> T raise {
  runtime_error("undefined variable: name '\{name}' is not bound")
}

///|
fn[T] missing_field_error(name : String, target : Value) -> T raise {
  runtime_error(
    "missing field: record has no field '\{name}' in \{typed_value_summary(target)}",
  )
}

///|
fn[T] missing_function_error(name : String) -> T raise {
  runtime_error("missing function: name '\{name}' is not bound as a function")
}

///|
fn[T] call_non_function_error(actual : Value) -> T raise {
  runtime_error(
    "call error: expected Function, got \{typed_value_summary(actual)}",
  )
}

///|
fn[T] arity_error(expected : Int, actual : Int) -> T raise {
  runtime_error("arity error: expected \{expected} arguments, got \{actual}")
}

///|
fn[T] type_error_unary(
  operator : String,
  expected : String,
  actual : Value,
) -> T raise {
  runtime_error(
    "type error: \{operator} expected \{expected}, got \{typed_value_summary(actual)}",
  )
}

///|
fn[T] type_error_binary(
  operator : String,
  expected : String,
  left : Value,
  right : Value,
) -> T raise {
  runtime_error(
    "type error: \{operator} expected \{expected}, got (\{typed_value_summary(left)}, \{typed_value_summary(right)})",
  )
}
