///|
/// Surface syntax AST definitions
enum SurfaceExpr {
  SLocated(SourceSpan, SurfaceExpr)
  SIntLit(Int)
  SBoolLit(Bool)
  SStringLit(String)
  SNilLit
  SList(Array[SurfaceExpr])
  SVar(String)
  SRecord(Array[SurfaceRecordField])
  SVariant(String, SurfaceExpr)
  SIf(Array[SurfaceIfCondArm], SurfaceExpr)
  SLet(SurfacePattern, SurfaceExpr, SurfaceExpr)
  SLetAnd(Array[(SurfacePattern, SurfaceExpr)], SurfaceExpr)
  SDo(SurfaceExpr, SurfaceExpr)
  SLetFun(String, Array[SurfacePattern], SurfaceExpr, SurfaceExpr)
  SLetRec(String, Array[SurfacePattern], SurfaceExpr, SurfaceExpr)
  SLetRecAnd(Array[(String, Array[SurfacePattern], SurfaceExpr)], SurfaceExpr)
  SLambda(Array[SurfacePattern], SurfaceExpr)
  SCall(SurfaceExpr, Array[SurfaceExpr])
  SRefNew(SurfaceExpr)
  SRefGet(SurfaceExpr)
  SRefSet(SurfaceExpr, SurfaceExpr)
  SRefUpdate(BinOp, SurfaceExpr, SurfaceExpr)
  SField(SurfaceExpr, String)
  SUnary(UnOp, SurfaceExpr)
  SBinary(BinOp, SurfaceExpr, SurfaceExpr)
} derive(Debug)

///|
priv enum SurfaceIfCondArm {
  SIfCondArm(SurfaceExpr, SurfaceIfGuard)
} derive(Debug)

///|
priv enum SurfaceIfPatternArm {
  SIfPatternArm(SurfacePattern, SurfaceIfGuard)
} derive(Debug)

///|
priv enum SurfaceIfGuard {
  SIfThen(SurfaceExpr)
  SIfAnd(Array[SurfaceIfCondArm])
  SIfIs(SurfaceExpr, Array[SurfaceIfPatternArm])
} derive(Debug)

///|
priv enum SurfaceRecordField {
  SRecordField(String, SurfaceExpr)
  SRecordShorthand(String)
} derive(Debug)

///|
priv enum SurfacePattern {
  SPBind(String)
  SPInt(Int)
  SPBool(Bool)
  SPString(String)
  SPNil
  SPOr(Array[SurfacePattern])
  SPVariant(String, SurfacePattern)
  SPList(Array[SurfacePattern])
  SPListRest(Array[SurfacePattern], String, Array[SurfacePattern])
  SPRecord(Array[SurfaceRecordPatternField])
} derive(Debug)

///|
priv enum SurfaceRecordPatternField {
  SPRecordField(String, SurfacePattern)
  SPRecordShorthand(String)
} derive(Debug)

///|
/// Core AST definitions
enum Expr {
  Located(SourceSpan, Expr)
  IntLit(Int)
  BoolLit(Bool)
  StringLit(String)
  NilLit
  List(Array[Expr])
  Var(String)
  Record(Array[(String, Expr)])
  Variant(String, Expr)
  If(Array[IfCondArm], Expr)
  Let(MatchPattern, Expr, Expr)
  LetAnd(Array[(MatchPattern, Expr)], Expr)
  LetRec(String, Array[MatchPattern], Expr, Expr)
  LetRecAnd(Array[(String, Array[MatchPattern], Expr)], Expr)
  Lambda(Array[MatchPattern], Expr)
  Call(Expr, Array[Expr])
  RefNew(Expr)
  RefGet(Expr)
  RefSet(Expr, Expr)
  RefUpdate(BinOp, Expr, Expr)
  Field(Expr, String)
  Unary(UnOp, Expr)
  Binary(BinOp, Expr, Expr)
} derive(Debug)

///|
priv enum IfCondArm {
  IfCondArm(Expr, IfGuard)
} derive(Debug)

///|
priv enum IfPatternArm {
  IfPatternArm(MatchPattern, IfGuard)
} derive(Debug)

///|
priv enum IfGuard {
  IfThen(Expr)
  IfAnd(Array[IfCondArm])
  IfIs(Expr, Array[IfPatternArm])
} derive(Debug)

///|
priv enum MatchPattern {
  PBind(String)
  PInt(Int)
  PBool(Bool)
  PString(String)
  PNil
  POr(Array[MatchPattern])
  PVariant(String, MatchPattern)
  PList(Array[MatchPattern])
  PListRest(Array[MatchPattern], String, Array[MatchPattern])
  PRecord(Array[(String, MatchPattern)])
} derive(Debug)

///|
priv enum BinOp {
  Add
  Sub
  Mul
  Div
  Mod
  Eq
  Ne
  Lt
  Le
  Gt
  Ge
  And
  Or
} derive(Debug)

///|
priv enum UnOp {
  Neg
  Not
} derive(Debug)

///|
/// Dynamic runtime values + environment model
enum Value {
  VInt(Int)
  VBool(Bool)
  VString(String)
  VNil
  VList(Array[Value])
  VRecord(@hashmap.HashMap[String, Value])
  VVariant(String, Value)
  VRef(@ref.Ref[Value])
  VClosure(Array[MatchPattern], Expr, Env)
  VRecClosure(
    String,
    Array[MatchPattern],
    Expr,
    Env,
    Array[(String, Array[MatchPattern], Expr)]
  )
} derive(Debug)

///|
type Env = @hashmap.HashMap[String, Value]

///|
priv suberror EvalError {
  RuntimeErrorAt(String, SourceSpan)
} derive(Debug)

///|
/// Public API
fn eval(expr : Expr) -> Value raise {
  eval_with_env(expr, @hashmap.new())
}

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
        Lambda(params.map(param => desugar_pattern(param)), desugar(func_body)),
        desugar(body),
      )
    SLetRec(name, params, func_body, body) =>
      LetRec(
        name,
        params.map(param => desugar_pattern(param)),
        desugar(func_body),
        desugar(body),
      )
    SLetRecAnd(defs, body) =>
      LetRecAnd(defs.map(def => desugar_let_rec_def(def)), desugar(body))
    SLambda(params, body) =>
      Lambda(params.map(param => desugar_pattern(param)), desugar(body))
    SCall(func_expr, arg_exprs) =>
      Call(desugar(func_expr), arg_exprs.map(arg => desugar(arg)))
    SRefNew(inner) => RefNew(desugar(inner))
    SRefGet(inner) => RefGet(desugar(inner))
    SRefSet(ref_expr, value_expr) =>
      RefSet(desugar(ref_expr), desugar(value_expr))
    SRefUpdate(op, ref_expr, value_expr) =>
      RefUpdate(op, desugar(ref_expr), desugar(value_expr))
    SField(target, name) => Field(desugar(target), name)
    SUnary(op, one) => Unary(op, desugar(one))
    SBinary(op, left, right) => Binary(op, desugar(left), desugar(right))
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
  def : (String, Array[SurfacePattern], SurfaceExpr),
) -> (String, Array[MatchPattern], Expr) {
  let (name, params, func_body) = def
  (name, params.map(param => desugar_pattern(param)), desugar(func_body))
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
    BoolLit(v) => VBool(v)
    StringLit(v) => VString(v)
    NilLit => VNil
    List(items) => VList(eval_expr_list(items, env))
    Var(name) => lookup(env, name)
    Record(fields) => VRecord(eval_record_fields(fields, env))
    Variant(tag, value_expr) => VVariant(tag, eval_with_env(value_expr, env))
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
      let func_value = eval_with_env(func_expr, env)
      let args = eval_expr_list(arg_exprs, env)
      apply(func_value, args)
    }
    RefNew(inner) => VRef(@ref.new(eval_with_env(inner, env)))
    RefGet(ref_expr) =>
      match eval_with_env(ref_expr, env) {
        VRef(cell) => cell.val
        value => raise type_error_unary("operator '!'", "Ref", value)
      }
    RefSet(ref_expr, value_expr) => {
      let ref_value = eval_with_env(ref_expr, env)
      let new_value = eval_with_env(value_expr, env)
      match ref_value {
        VRef(cell) => {
          cell.val = new_value
          new_value
        }
        value =>
          raise type_error_unary("operator '='", "Ref on left side", value)
      }
    }
    RefUpdate(op, ref_expr, value_expr) => {
      let ref_value = eval_with_env(ref_expr, env)
      match ref_value {
        VRef(cell) => {
          let old_value = cell.val
          let new_value = match op {
            Add | Sub | Mul | Div | Mod => {
              let right = eval_with_env(value_expr, env)
              eval_binary(op, old_value, right)
            }
            And =>
              if truthy(old_value) {
                eval_with_env(value_expr, env)
              } else {
                old_value
              }
            Or =>
              if truthy(old_value) {
                old_value
              } else {
                eval_with_env(value_expr, env)
              }
            _ => raise runtime_error("invalid operator for ref update")
          }
          cell.val = new_value
          new_value
        }
        value =>
          raise type_error_unary(
            ref_update_operator_text(op),
            "Ref on left side",
            value,
          )
      }
    }
    Field(target, name) => {
      let target_value = eval_with_env(target, env)
      match target_value {
        VRecord(fields) =>
          match fields.get(name) {
            Some(value) => value
            None => raise missing_field_error(name, target_value)
          }
        value => raise type_error_unary("operator '.'", "Record", value)
      }
    }
    Unary(op, one) => eval_unary(op, eval_with_env(one, env))
    Binary(op, left, right) =>
      match op {
        And => {
          let (left_value, left_env) = eval_with_env_and_bindings(left, env)
          if truthy(left_value) {
            let (right_value, _) = eval_with_env_and_bindings(right, left_env)
            right_value
          } else {
            left_value
          }
        }
        Or => {
          let (left_value, left_env) = eval_with_env_and_bindings(left, env)
          if truthy(left_value) {
            left_value
          } else {
            let (right_value, _) = eval_with_env_and_bindings(right, left_env)
            right_value
          }
        }
        _ =>
          eval_binary(op, eval_with_env(left, env), eval_with_env(right, env))
      }
  }
}

///|
fn eval_with_env_and_bindings(expr : Expr, env : Env) -> (Value, Env) raise {
  match expr {
    Located(span, inner) =>
      eval_with_env_and_bindings(inner, env) catch {
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
    Binary(And, left, right) => {
      let (left_value, left_env) = eval_with_env_and_bindings(left, env)
      if truthy(left_value) {
        eval_with_env_and_bindings(right, left_env)
      } else {
        (left_value, env)
      }
    }
    Binary(Or, left, right) => {
      let (left_value, left_env) = eval_with_env_and_bindings(left, env)
      if truthy(left_value) {
        (left_value, left_env)
      } else {
        eval_with_env_and_bindings(right, left_env)
      }
    }
    _ => (eval_with_env(expr, env), env)
  }
}

///|
fn eval_condition_bindings(cond : Expr, env : Env) -> (Bool, Env) raise {
  let (value, next_env) = eval_with_env_and_bindings(cond, env)
  if truthy(value) {
    (true, next_env)
  } else {
    (false, env)
  }
}

///|
fn eval_if_cond_arms(
  arms : Array[IfCondArm],
  else_expr : Expr,
  env : Env,
  i : Int,
) -> Value raise {
  match eval_if_cond_arms_with_fallback(arms, Some(else_expr), env, i) {
    Some(result) => result
    None => eval_with_env(else_expr, env)
  }
}

///|
fn eval_if_cond_arms_with_fallback(
  arms : Array[IfCondArm],
  fallback : Expr?,
  env : Env,
  i : Int,
) -> Value? raise {
  if i >= arms.length() {
    return match fallback {
      Some(default_expr) => Some(eval_with_env(default_expr, env))
      None => None
    }
  }
  let IfCondArm(cond, arm_guard) = arms[i]
  let (passes, base_env) = eval_condition_bindings(cond, env)
  if !passes {
    return eval_if_cond_arms_with_fallback(arms, fallback, env, i + 1)
  }
  match eval_if_guard(arm_guard, base_env) {
    Some(result) => Some(result)
    None => eval_if_cond_arms_with_fallback(arms, fallback, env, i + 1)
  }
}

///|
/// Helpers: environment and apply
fn lookup(env : Env, name : String) -> Value raise {
  match env.get(name) {
    Some(value) => value
    None => raise undefined_variable_error(name)
  }
}

///|
fn eval_let_and_bindings(
  bindings : Array[(MatchPattern, Expr)],
  env : Env,
) -> Env raise {
  let evaluated = eval_let_and_values(bindings, env, 0, [])
  bind_let_and_values(evaluated, env, 0)
}

///|
fn eval_let_and_values(
  bindings : Array[(MatchPattern, Expr)],
  env : Env,
  i : Int,
  acc : Array[(MatchPattern, Value)],
) -> Array[(MatchPattern, Value)] raise {
  if i >= bindings.length() {
    return acc
  }
  let (pattern, value_expr) = bindings[i]
  acc.push((pattern, eval_with_env(value_expr, env)))
  eval_let_and_values(bindings, env, i + 1, acc)
}

///|
fn bind_let_and_values(
  evaluated : Array[(MatchPattern, Value)],
  env : Env,
  i : Int,
) -> Env raise {
  if i >= evaluated.length() {
    return env
  }
  let (pattern, value) = evaluated[i]
  let next_env = bind_pattern(pattern, value, env)
  bind_let_and_values(evaluated, next_env, i + 1)
}

///|
fn build_rec_env(
  defs : Array[(String, Array[MatchPattern], Expr)],
  closure_env : Env,
) -> Env {
  build_rec_env_from(defs, closure_env, closure_env, 0)
}

///|
fn build_rec_env_from(
  defs : Array[(String, Array[MatchPattern], Expr)],
  closure_env : Env,
  env : Env,
  i : Int,
) -> Env {
  if i >= defs.length() {
    return env
  }
  let (name, _, _) = defs[i]
  let closure = rec_closure_from_def(defs[i], closure_env, defs)
  build_rec_env_from(defs, closure_env, env.add(name, closure), i + 1)
}

///|
fn rec_closure_from_def(
  def : (String, Array[MatchPattern], Expr),
  closure_env : Env,
  defs : Array[(String, Array[MatchPattern], Expr)],
) -> Value {
  let (name, params, body) = def
  VRecClosure(name, params, body, closure_env, defs)
}

///|
fn apply(func_value : Value, args : Array[Value]) -> Value raise {
  match func_value {
    VClosure(params, body, closure_env) => {
      let call_env = bind_patterns(params, args, closure_env)
      eval_with_env(body, call_env)
    }
    VRecClosure(_, params, body, closure_env, defs) => {
      let call_base_env = build_rec_env(defs, closure_env)
      let call_env = bind_patterns(params, args, call_base_env)
      eval_with_env(body, call_env)
    }
    _ => raise call_non_function_error(func_value)
  }
}

///|
fn bind_patterns(
  patterns : Array[MatchPattern],
  args : Array[Value],
  base : Env,
) -> Env raise {
  if patterns.length() < args.length() {
    raise arity_error(patterns.length(), args.length())
  }
  if patterns.length() > args.length() {
    raise arity_error(patterns.length(), args.length())
  }
  patterns.foldi(init=base, (i, acc_env, pattern) => {
    bind_pattern(pattern, args[i], acc_env)
  })
}

///|
/// Helpers: expression list evaluation
fn eval_expr_list(exprs : Array[Expr], env : Env) -> Array[Value] raise {
  exprs.map(expr => eval_with_env(expr, env))
}

///|
fn eval_record_fields(
  fields : Array[(String, Expr)],
  env : Env,
) -> @hashmap.HashMap[String, Value] raise {
  fields.fold(init=@hashmap.new(), (acc, field) => {
    let (name, expr) = field
    acc.add(name, eval_with_env(expr, env))
  })
}

///|
fn eval_if_guard(arm_guard : IfGuard, env : Env) -> Value? raise {
  match arm_guard {
    IfThen(body) => Some(eval_with_env(body, env))
    IfAnd(arms) => eval_if_cond_arms_with_fallback(arms, None, env, 0)
    IfIs(value_expr, arms) => {
      let value = eval_with_env(value_expr, env)
      eval_if_pattern_arms_with_fallback(value, arms, None, env, 0)
    }
  }
}

///|
fn eval_if_pattern_arms_with_fallback(
  value : Value,
  arms : Array[IfPatternArm],
  fallback : Expr?,
  env : Env,
  i : Int,
) -> Value? raise {
  if i >= arms.length() {
    return match fallback {
      Some(default_expr) => Some(eval_with_env(default_expr, env))
      None => None
    }
  }
  let IfPatternArm(pattern, arm_guard) = arms[i]
  match try_bind_pattern(pattern, value, env) {
    Some(bound_env) =>
      match eval_if_guard(arm_guard, bound_env) {
        Some(result) => Some(result)
        None =>
          eval_if_pattern_arms_with_fallback(value, arms, fallback, env, i + 1)
      }
    None =>
      eval_if_pattern_arms_with_fallback(value, arms, fallback, env, i + 1)
  }
}

///|
fn bind_pattern(pattern : MatchPattern, value : Value, env : Env) -> Env raise {
  match try_bind_pattern(pattern, value, env) {
    Some(bound_env) => bound_env
    None =>
      raise runtime_error(
        "pattern match failure: expected " +
        pattern_summary(pattern) +
        ", got " +
        value_summary(value),
      )
  }
}

///|
fn try_bind_pattern(pattern : MatchPattern, value : Value, env : Env) -> Env? {
  match pattern {
    PBind(name) =>
      if name == "_" {
        Some(env)
      } else {
        Some(env.add(name, value))
      }
    PInt(expected) =>
      match value {
        VInt(actual) if actual == expected => Some(env)
        _ => None
      }
    PBool(expected) =>
      match value {
        VBool(actual) if actual == expected => Some(env)
        _ => None
      }
    PString(expected) =>
      match value {
        VString(actual) if actual == expected => Some(env)
        _ => None
      }
    PNil =>
      match value {
        VNil => Some(env)
        _ => None
      }
    POr(patterns) => try_bind_or_pattern(patterns, value, env, 0)
    PVariant(tag, inner) =>
      match value {
        VVariant(value_tag, payload) =>
          if tag == value_tag {
            try_bind_pattern(inner, payload, env)
          } else {
            None
          }
        _ => None
      }
    PList(items) =>
      match value {
        VList(values) =>
          if items.length() != values.length() {
            None
          } else {
            try_bind_list_pattern(items, values, env, 0)
          }
        _ => None
      }
    PListRest(prefix, rest_name, suffix) =>
      match value {
        VList(values) =>
          try_bind_list_rest_pattern(prefix, rest_name, suffix, values, env)
        _ => None
      }
    PRecord(fields) =>
      match value {
        VRecord(values) => try_bind_record_match_pattern(fields, values, env, 0)
        _ => None
      }
  }
}

///|
fn try_bind_list_pattern(
  patterns : Array[MatchPattern],
  values : Array[Value],
  env : Env,
  i : Int,
) -> Env? {
  if i >= patterns.length() {
    return Some(env)
  }
  match try_bind_pattern(patterns[i], values[i], env) {
    Some(next_env) => try_bind_list_pattern(patterns, values, next_env, i + 1)
    None => None
  }
}

///|
fn try_bind_record_match_pattern(
  patterns : Array[(String, MatchPattern)],
  values : @hashmap.HashMap[String, Value],
  env : Env,
  i : Int,
) -> Env? {
  if i >= patterns.length() {
    return Some(env)
  }
  let (field_name, pattern) = patterns[i]
  match values.get(field_name) {
    Some(value) =>
      match try_bind_pattern(pattern, value, env) {
        Some(next_env) =>
          try_bind_record_match_pattern(patterns, values, next_env, i + 1)
        None => None
      }
    None => None
  }
}

///|
fn try_bind_list_rest_pattern(
  prefix : Array[MatchPattern],
  rest_name : String,
  suffix : Array[MatchPattern],
  values : Array[Value],
  env : Env,
) -> Env? {
  let prefix_len = prefix.length()
  let suffix_len = suffix.length()
  if values.length() < prefix_len + suffix_len {
    return None
  }
  match try_bind_list_pattern(prefix, values, env, 0) {
    Some(prefix_env) => {
      let middle_end = values.length() - suffix_len
      let env_with_rest = if rest_name == "_" {
        prefix_env
      } else {
        prefix_env.add(
          rest_name,
          VList(slice_values(values, prefix_len, middle_end)),
        )
      }
      try_bind_list_suffix_pattern(suffix, values, env_with_rest, middle_end, 0)
    }
    None => None
  }
}

///|
fn try_bind_list_suffix_pattern(
  suffix : Array[MatchPattern],
  values : Array[Value],
  env : Env,
  start : Int,
  i : Int,
) -> Env? {
  if i >= suffix.length() {
    return Some(env)
  }
  match try_bind_pattern(suffix[i], values[start + i], env) {
    Some(next_env) =>
      try_bind_list_suffix_pattern(suffix, values, next_env, start, i + 1)
    None => None
  }
}

///|
fn slice_values(values : Array[Value], start : Int, end_ : Int) -> Array[Value] {
  slice_values_from(values, start, end_, [])
}

///|
fn slice_values_from(
  values : Array[Value],
  i : Int,
  end_ : Int,
  acc : Array[Value],
) -> Array[Value] {
  if i >= end_ {
    return acc
  }
  acc.push(values[i])
  slice_values_from(values, i + 1, end_, acc)
}

///|
fn try_bind_or_pattern(
  patterns : Array[MatchPattern],
  value : Value,
  env : Env,
  i : Int,
) -> Env? {
  if i >= patterns.length() {
    return None
  }
  match try_bind_pattern(patterns[i], value, env) {
    Some(bound_env) => Some(bound_env)
    None => try_bind_or_pattern(patterns, value, env, i + 1)
  }
}

///|
/// Helpers: operators and predicates
fn truthy(value : Value) -> Bool {
  match value {
    VBool(v) => v
    VNil => false
    _ => true
  }
}

///|
fn pattern_summary(pattern : MatchPattern) -> String {
  match pattern {
    PBind(name) => name
    PInt(value) => value.to_string()
    PBool(value) => value.to_string()
    PString(value) => "\"" + value + "\""
    PNil => "nil"
    POr(patterns) => join_pattern_summaries(patterns, 0)
    PVariant(tag, inner) => "#" + tag + "(" + pattern_summary(inner) + ")"
    PList(items) => "[" + join_pattern_list(items, 0) + "]"
    PListRest(prefix, rest_name, suffix) =>
      "[" + join_list_rest_pattern_parts(prefix, rest_name, suffix) + "]"
    PRecord(fields) => "{" + join_record_pattern_fields(fields, 0) + "}"
  }
}

///|
fn join_pattern_summaries(patterns : Array[MatchPattern], i : Int) -> String {
  if i >= patterns.length() {
    return ""
  }
  let current = pattern_summary(patterns[i])
  if i + 1 >= patterns.length() {
    current
  } else {
    current + " | " + join_pattern_summaries(patterns, i + 1)
  }
}

///|
fn join_pattern_list(patterns : Array[MatchPattern], i : Int) -> String {
  if i >= patterns.length() {
    return ""
  }
  let current = pattern_summary(patterns[i])
  if i + 1 >= patterns.length() {
    current
  } else {
    current + ", " + join_pattern_list(patterns, i + 1)
  }
}

///|
fn join_list_rest_pattern_parts(
  prefix : Array[MatchPattern],
  rest_name : String,
  suffix : Array[MatchPattern],
) -> String {
  let prefix_text = join_pattern_list(prefix, 0)
  let rest_text = if rest_name == "_" { ".." } else { ".." + rest_name }
  let suffix_text = join_pattern_list(suffix, 0)
  if prefix.length() == 0 && suffix.length() == 0 {
    rest_text
  } else if prefix.length() == 0 {
    rest_text + ", " + suffix_text
  } else if suffix.length() == 0 {
    prefix_text + ", " + rest_text
  } else {
    prefix_text + ", " + rest_text + ", " + suffix_text
  }
}

///|
fn join_record_pattern_fields(
  fields : Array[(String, MatchPattern)],
  i : Int,
) -> String {
  if i >= fields.length() {
    return ""
  }
  let (field_name, field_pattern) = fields[i]
  let current = match field_pattern {
    PBind(name) if name == field_name => field_name
    _ => field_name + ": " + pattern_summary(field_pattern)
  }
  if i + 1 >= fields.length() {
    current
  } else {
    current + ", " + join_record_pattern_fields(fields, i + 1)
  }
}

///|
fn value_summary(value : Value) -> String {
  match value {
    VInt(v) => v.to_string()
    VBool(v) => v.to_string()
    VString(v) => "\"" + v + "\""
    VNil => "nil"
    VList(items) => "[" + join_value_list(items, 0) + "]"
    VRecord(fields) => "record(" + fields.length().to_string() + " fields)"
    VVariant(tag, payload) => "#" + tag + "(" + value_summary(payload) + ")"
    VRef(_) => "ref"
    VClosure(_, _, _) => "function"
    VRecClosure(_, _, _, _, _) => "function"
  }
}

///|
fn typed_value_summary(value : Value) -> String {
  match value {
    VInt(v) => "Int(" + v.to_string() + ")"
    VBool(v) => "Bool(" + v.to_string() + ")"
    VString(v) => "String(\"" + v + "\")"
    VNil => "Nil"
    VList(items) => "List([" + join_value_list(items, 0) + "])"
    VRecord(fields) => "Record(" + fields.length().to_string() + " fields)"
    VVariant(tag, payload) =>
      "Variant(" + "#" + tag + "(" + value_summary(payload) + ")" + ")"
    VRef(_) => "Ref"
    VClosure(_, _, _) => "Function"
    VRecClosure(_, _, _, _, _) => "Function"
  }
}

///|
fn join_value_list(values : Array[Value], i : Int) -> String {
  if i >= values.length() {
    return ""
  }
  let current = value_summary(values[i])
  if i + 1 >= values.length() {
    current
  } else {
    current + ", " + join_value_list(values, i + 1)
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
  raise runtime_error("undefined variable: name '" + name + "' is not bound")
}

///|
fn[T] missing_field_error(name : String, target : Value) -> T raise {
  raise runtime_error(
    "missing field: record has no field '" +
    name +
    "' in " +
    typed_value_summary(target),
  )
}

///|
fn[T] call_non_function_error(actual : Value) -> T raise {
  raise runtime_error(
    "call error: expected Function, got " + typed_value_summary(actual),
  )
}

///|
fn[T] arity_error(expected : Int, actual : Int) -> T raise {
  raise runtime_error(
    "arity error: expected " +
    expected.to_string() +
    " arguments, got " +
    actual.to_string(),
  )
}

///|
fn[T] type_error_unary(
  operator : String,
  expected : String,
  actual : Value,
) -> T raise {
  raise runtime_error(
    "type error: " +
    operator +
    " expected " +
    expected +
    ", got " +
    typed_value_summary(actual),
  )
}

///|
fn[T] type_error_binary(
  operator : String,
  expected : String,
  left : Value,
  right : Value,
) -> T raise {
  raise runtime_error(
    "type error: " +
    operator +
    " expected " +
    expected +
    ", got (" +
    typed_value_summary(left) +
    ", " +
    typed_value_summary(right) +
    ")",
  )
}

///|
fn eval_unary(op : UnOp, value : Value) -> Value raise {
  match op {
    Neg =>
      match value {
        VInt(v) => VInt(-v)
        _ => raise type_error_unary("unary '-'", "Int", value)
      }
    Not => VBool(!truthy(value))
  }
}

///|
fn eval_binary(op : BinOp, left : Value, right : Value) -> Value raise {
  match op {
    Add =>
      match (left, right) {
        (VInt(a), VInt(b)) => VInt(a + b)
        (VString(a), VString(b)) => VString(a + b)
        _ =>
          raise type_error_binary(
            "operator '+'", "(Int, Int) or (String, String)", left, right,
          )
      }
    Sub =>
      match (left, right) {
        (VInt(a), VInt(b)) => VInt(a - b)
        _ => raise type_error_binary("operator '-'", "(Int, Int)", left, right)
      }
    Mul =>
      match (left, right) {
        (VInt(a), VInt(b)) => VInt(a * b)
        _ => raise type_error_binary("operator '*'", "(Int, Int)", left, right)
      }
    Div =>
      match (left, right) {
        (VInt(_), VInt(0)) => VInt(0)
        (VInt(a), VInt(b)) => VInt(a / b)
        _ => raise type_error_binary("operator '/'", "(Int, Int)", left, right)
      }
    Mod =>
      match (left, right) {
        (VInt(a), VInt(0)) => VInt(a)
        (VInt(a), VInt(b)) => VInt(a % b)
        _ => raise type_error_binary("operator '%'", "(Int, Int)", left, right)
      }
    Eq => VBool(value_eq(left, right))
    Ne => VBool(!value_eq(left, right))
    Lt =>
      match (left, right) {
        (VInt(a), VInt(b)) => VBool(a < b)
        _ => raise type_error_binary("operator '<'", "(Int, Int)", left, right)
      }
    Le =>
      match (left, right) {
        (VInt(a), VInt(b)) => VBool(a <= b)
        _ => raise type_error_binary("operator '<='", "(Int, Int)", left, right)
      }
    Gt =>
      match (left, right) {
        (VInt(a), VInt(b)) => VBool(a > b)
        _ => raise type_error_binary("operator '>'", "(Int, Int)", left, right)
      }
    Ge =>
      match (left, right) {
        (VInt(a), VInt(b)) => VBool(a >= b)
        _ => raise type_error_binary("operator '>='", "(Int, Int)", left, right)
      }
    And => if truthy(left) { right } else { left }
    Or => if truthy(left) { left } else { right }
  }
}

///|
fn ref_update_operator_text(op : BinOp) -> String {
  match op {
    Add => "operator '+='"
    Sub => "operator '-='"
    Mul => "operator '*='"
    Div => "operator '/='"
    Mod => "operator '%='"
    And => "operator '&&='"
    Or => "operator '||='"
    _ => "ref update operator"
  }
}

///|
fn value_eq(a : Value, b : Value) -> Bool {
  match (a, b) {
    (VInt(x), VInt(y)) => x == y
    (VBool(x), VBool(y)) => x == y
    (VString(x), VString(y)) => x == y
    (VNil, VNil) => true
    (VList(x), VList(y)) => list_eq(x, y)
    (VRecord(x), VRecord(y)) => record_eq(x, y)
    (VVariant(tag1, value1), VVariant(tag2, value2)) =>
      tag1 == tag2 && value_eq(value1, value2)
    _ => false
  }
}

///|
fn record_eq(
  left : @hashmap.HashMap[String, Value],
  right : @hashmap.HashMap[String, Value],
) -> Bool {
  if left.length() != right.length() {
    return false
  }
  left.fold(init=true, (acc, name, value) => {
    if !acc {
      false
    } else {
      match right.get(name) {
        Some(other) => value_eq(value, other)
        None => false
      }
    }
  })
}

///|
fn list_eq(left : Array[Value], right : Array[Value]) -> Bool {
  if left.length() != right.length() {
    return false
  }
  list_eq_from(left, right, 0)
}

///|
fn list_eq_from(left : Array[Value], right : Array[Value], i : Int) -> Bool {
  if i >= left.length() {
    return true
  }
  if !value_eq(left[i], right[i]) {
    return false
  }
  list_eq_from(left, right, i + 1)
}

///|
pub fn eval_source_is_string(source : String, expected : String) -> Bool {
  try eval_source(source) catch {
    _ => false
  } noraise {
    VString(v) => v == expected
    _ => false
  }
}

///|
pub fn eval_source_is_bool(source : String, expected : Bool) -> Bool {
  try eval_source(source) catch {
    _ => false
  } noraise {
    VBool(v) => v == expected
    _ => false
  }
}

///|
pub fn eval_error_text(source : String) -> String? {
  try eval_source(source) catch {
    RuntimeErrorAt(message, span) =>
      Some(message + " at " + format_source_span(span))
    _ => None
  } noraise {
    _ => None
  }
}
