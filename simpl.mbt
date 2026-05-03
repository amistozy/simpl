///|
/// Surface syntax AST definitions
enum SurfaceExpr {
  SLocated(SourceSpan, SurfaceExpr)
  SIntLit(Int)
  SBoolLit(Bool)
  SStringLit(String)
  SNilLit
  SUnderscore
  SList(Array[SurfaceListItem])
  SVar(String)
  SRecord(Array[SurfaceRecordField])
  SVariant(String, SurfaceExpr)
  SIf(Array[SurfaceIfCondArm], SurfaceExpr)
  SLet(SurfacePattern, SurfaceExpr, SurfaceExpr)
  SLetAnd(Array[(SurfacePattern, SurfaceExpr)], SurfaceExpr)
  SDo(SurfaceExpr, SurfaceExpr)
  SProbe(SurfaceExpr, SurfaceExpr)
  SGuard(SurfaceGuardCondArm, SurfaceExpr?, SurfaceExpr)
  SLetFun(String, Array[SurfaceParam], SurfaceExpr, SurfaceExpr)
  SLetRec(String, Array[SurfaceParam], SurfaceExpr, SurfaceExpr)
  SLetRecAnd(Array[(String, Array[SurfaceParam], SurfaceExpr)], SurfaceExpr)
  SWith(Array[SurfaceParam], SurfaceExpr, SurfaceExpr)
  SLambda(Array[SurfaceParam], SurfaceExpr)
  SFnEta(SurfaceExpr)
  SCall(SurfaceExpr, Array[SurfaceCallArg])
  SField(SurfaceExpr, String)
  SUnary(UnOp, SurfaceExpr)
  SBinary(BinOp, SurfaceExpr, SurfaceExpr)
} derive(Debug)

///|
priv enum SurfaceParam {
  SParam(SurfacePattern, SurfaceExpr?)
} derive(Debug)

///|
priv enum SurfaceCallArg {
  SArgPos(SurfaceExpr)
  SArgNamed(String, SurfaceExpr)
  STrailingArgPos(SurfaceExpr)
} derive(Debug)

///|
priv enum SurfaceListItem {
  SListOne(SurfaceExpr)
  SListSpread(SurfaceExpr)
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
priv enum SurfaceGuardCondArm {
  SGuardCondArm(SurfaceExpr, SurfaceGuardGuard)
} derive(Debug)

///|
priv enum SurfaceGuardPatternArm {
  SGuardPatternArm(SurfacePattern, SurfaceGuardGuard)
} derive(Debug)

///|
priv enum SurfaceGuardGuard {
  SGuardPass
  SGuardAnd(SurfaceGuardCondArm)
  SGuardIs(SurfaceExpr, SurfaceGuardPatternArm)
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
  SPAs(SurfacePattern, String)
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
priv enum Expr {
  Located(SourceSpan, Expr)
  IntLit(Int)
  BoolLit(Bool)
  StringLit(String)
  NilLit
  List(Array[ListItem])
  Var(String)
  If(Array[IfCondArm], Expr)
  Let(MatchPattern, Expr, Expr)
  LetAnd(Array[(MatchPattern, Expr)], Expr)
  LetRec(String, Array[Param], Expr, Expr)
  LetRecAnd(Array[(String, Array[Param], Expr)], Expr)
  Lambda(Array[Param], Expr)
  Call(Expr, Array[CallArg])
  Field(Expr, String)
} derive(Debug)

///|
priv enum Param {
  Param(MatchPattern, Expr?, String?)
} derive(Debug)

///|
priv enum CallArg {
  ArgPos(Expr)
  ArgNamed(String, Expr)
} derive(Debug)

///|
priv enum ListItem {
  ListOne(Expr)
  ListSpread(Expr)
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
  PAs(MatchPattern, String)
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
  Pow
  Eq
  Ne
  Lt
  Le
  Gt
  Ge
  And
  Or
  RefSet
  RefUpdateAdd
  RefUpdateSub
  RefUpdateMul
  RefUpdateDiv
  RefUpdateMod
  RefUpdateAnd
  RefUpdateOr
} derive(Debug)

///|
priv enum UnOp {
  Neg
  Bang
  Dollar
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
  VRef(mut value~ : Value)
  VClosure(Array[Param], Expr, Env)
  VRecClosure(
    String,
    Array[Param],
    Expr,
    Env,
    Array[(String, Array[Param], Expr)]
  )
  VBuiltin(Builtin)
} derive(Debug)

///|
type Env = @hashmap.HashMap[String, Value]

///|
priv enum Builtin {
  BRef
  BSay
  BMap
  BFilter
  BFold
  BLength
  BReverse
  BMax
  BMin
  BSum
  BOpAdd
  BOpSub
  BOpMul
  BOpDiv
  BOpMod
  BOpPow
  BOpEq
  BOpNe
  BOpLt
  BOpLe
  BOpGt
  BOpGe
  BOpNeg
  BOpBang
  BOpDollar
  BOpRefSet
  BOpRefUpdateAdd
  BOpRefUpdateSub
  BOpRefUpdateMul
  BOpRefUpdateDiv
  BOpRefUpdateMod
  BOpAnd
  BOpOr
  BOpRefUpdateAnd
  BOpRefUpdateOr
  BRecord
  BVariant
} derive(Debug)

///|
priv suberror EvalError {
  RuntimeErrorAt(String, SourceSpan)
} derive(Debug)

///|
pub impl Show for SurfaceExpr with output(self : SurfaceExpr, logger : &Logger) -> Unit {
  logger.write_string(surface_expr_pretty(self))
}

///|
pub impl Show for Value with output(self : Value, logger : &Logger) -> Unit {
  logger.write_string(value_pretty(self, 6))
}

///|
fn eval(expr : Expr) -> Value raise {
  eval_with_env(expr, initial_env())
}

///|
fn initial_env() -> Env {
  builtin_bindings().fold(init=@hashmap.new(), (env, binding) => {
    let (name, builtin) = binding
    env.add(name, VBuiltin(builtin))
  })
}

///|
fn builtin_bindings() -> Array[(String, Builtin)] {
  [
    ("ref", BRef),
    ("say", BSay),
    ("map", BMap),
    ("filter", BFilter),
    ("fold", BFold),
    ("length", BLength),
    ("reverse", BReverse),
    ("max", BMax),
    ("min", BMin),
    ("sum", BSum),
    (builtin_name(BOpAdd), BOpAdd),
    (builtin_name(BOpSub), BOpSub),
    (builtin_name(BOpMul), BOpMul),
    (builtin_name(BOpDiv), BOpDiv),
    (builtin_name(BOpMod), BOpMod),
    (builtin_name(BOpPow), BOpPow),
    (builtin_name(BOpEq), BOpEq),
    (builtin_name(BOpNe), BOpNe),
    (builtin_name(BOpLt), BOpLt),
    (builtin_name(BOpLe), BOpLe),
    (builtin_name(BOpGt), BOpGt),
    (builtin_name(BOpGe), BOpGe),
    (builtin_name(BOpNeg), BOpNeg),
    (builtin_name(BOpBang), BOpBang),
    (builtin_name(BOpDollar), BOpDollar),
    (builtin_name(BOpRefSet), BOpRefSet),
    (builtin_name(BOpRefUpdateAdd), BOpRefUpdateAdd),
    (builtin_name(BOpRefUpdateSub), BOpRefUpdateSub),
    (builtin_name(BOpRefUpdateMul), BOpRefUpdateMul),
    (builtin_name(BOpRefUpdateDiv), BOpRefUpdateDiv),
    (builtin_name(BOpRefUpdateMod), BOpRefUpdateMod),
    (builtin_name(BOpAnd), BOpAnd),
    (builtin_name(BOpOr), BOpOr),
    (builtin_name(BOpRefUpdateAnd), BOpRefUpdateAnd),
    (builtin_name(BOpRefUpdateOr), BOpRefUpdateOr),
    (builtin_name(BRecord), BRecord),
    (builtin_name(BVariant), BVariant),
  ]
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
      validate_call_args_static(arg_exprs)
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
/// Helpers: environment and apply
fn lookup(env : Env, name : String) -> Value raise {
  guard env.get(name) is Some(value) else { undefined_variable_error(name) }
  value
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
fn build_rec_env(
  defs : Array[(String, Array[Param], Expr)],
  closure_env : Env,
) -> Env {
  defs.fold(init=closure_env, (env, def) => {
    let (name, _, _) = def
    let closure = rec_closure_def(def, closure_env, defs)
    env.add(name, closure)
  })
}

///|
fn rec_closure_def(
  def : (String, Array[Param], Expr),
  closure_env : Env,
  defs : Array[(String, Array[Param], Expr)],
) -> Value {
  let (name, params, body) = def
  VRecClosure(name, params, body, closure_env, defs)
}

///|
fn[T] builtin_type_error(
  name : String,
  expected : String,
  actual : Value,
) -> T raise {
  runtime_error(
    "builtin '\{name}' expected \{expected}, got \{typed_value_summary(actual)}",
  )
}

///|
fn bind_params(
  params : Array[Param],
  args : Array[EvaluatedCallArg],
  base : Env,
) -> Env raise {
  let assigned = params.map(_ => None)
  bind_named_args(params, args, assigned)
  bind_positional_args(params, args, assigned, 0, 0)
  let provided_count = count_assigned_values(assigned, 0, 0)
  let required_count = count_required_params(params, 0, 0)
  finalize_param_bindings(
    params, assigned, provided_count, required_count, base, 0,
  )
}

///|
fn bind_named_args(
  params : Array[Param],
  args : Array[EvaluatedCallArg],
  assigned : Array[Value?],
) -> Unit raise {
  for arg in args {
    guard arg is EArgNamed(name, value) else {  }
    guard find_param_index_by_name(params, name) is Some(param_i) else {
      runtime_error("unknown named argument: \{name}")
    }
    guard assigned[param_i] is None else {
      runtime_error("duplicate argument: \{name}")
    }
    assigned[param_i] = Some(value)
  }
}

///|
fn find_param_index_by_name(params : Array[Param], name : String) -> Int? {
  params.search_by(param => {
    let Param(_, _, param_name) = param
    param_name is Some(n) && n == name
  })
}

///|
fn bind_positional_args(
  params : Array[Param],
  args : Array[EvaluatedCallArg],
  assigned : Array[Value?],
  i : Int,
  next_param_i : Int,
) -> Unit raise {
  guard i < args.length() else {  }
  guard args[i] is EArgPos(value) else {
    bind_positional_args(params, args, assigned, i + 1, next_param_i)
  }
  guard find_next_unassigned_param(assigned, next_param_i) is Some(param_i) else {
    arity_error(params.length(), args.length())
  }
  assigned[param_i] = Some(value)
  bind_positional_args(params, args, assigned, i + 1, param_i + 1)
}

///|
fn find_next_unassigned_param(assigned : Array[Value?], i : Int) -> Int? {
  guard i < assigned.length() else { None }
  match assigned[i] {
    Some(_) => find_next_unassigned_param(assigned, i + 1)
    None => Some(i)
  }
}

///|
fn finalize_param_bindings(
  params : Array[Param],
  assigned : Array[Value?],
  provided_count : Int,
  required_count : Int,
  env : Env,
  i : Int,
) -> Env raise {
  guard i < params.length() else { env }
  let Param(pattern, default_expr, _) = params[i]
  let value = match assigned[i] {
    Some(v) => v
    None =>
      match default_expr {
        Some(expr) => eval_with_env(expr, env)
        None => arity_error(required_count, provided_count)
      }
  }
  let next_env = bind_pattern(pattern, value, env)
  finalize_param_bindings(
    params,
    assigned,
    provided_count,
    required_count,
    next_env,
    i + 1,
  )
}

///|
fn count_assigned_values(assigned : Array[Value?], i : Int, acc : Int) -> Int {
  guard i < assigned.length() else { acc }
  match assigned[i] {
    Some(_) => count_assigned_values(assigned, i + 1, acc + 1)
    None => count_assigned_values(assigned, i + 1, acc)
  }
}

///|
fn count_required_params(params : Array[Param], i : Int, acc : Int) -> Int {
  guard i < params.length() else { acc }
  let Param(_, default_expr, _) = params[i]
  match default_expr {
    Some(_) => count_required_params(params, i + 1, acc)
    None => count_required_params(params, i + 1, acc + 1)
  }
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
fn validate_call_args_static(args : Array[CallArg]) -> Unit raise {
  let seen_names = []
  for arg in args {
    guard arg is ArgNamed(name, _) else {  }
    if seen_names.contains(name) {
      runtime_error("duplicate argument: \{name}")
    }
    seen_names.push(name)
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
    guard env.get(name) is Some(func_value) && value_is_function(func_value) else {
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
    guard env.get(name) is Some(func_value) && value_is_function(func_value) else {
      missing_field_error(name, target_value)
    }
    apply(func_value, [EArgPos(target_value)] + args)
  }
  apply(value, args)
}

///|
fn value_is_function(value : Value) -> Bool {
  match value {
    VClosure(_) => true
    VRecClosure(_) => true
    VBuiltin(_) => true
    _ => false
  }
}

///|
fn apply_ufcs(
  name : String,
  target_value : Value,
  args : Array[EvaluatedCallArg],
  env : Env,
) -> Value raise {
  guard env.get(name) is Some(func_value) && value_is_function(func_value) else {
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

///|
fn int_pow(base : Int, exponent : Int) -> Int {
  guard exponent >= 0 else { 0 }
  for base = base, exponent = exponent, acc = 1 {
    if exponent == 0 {
      break acc
    } else if exponent % 2 == 0 {
      continue base * base, exponent / 2, acc
    } else {
      continue base, exponent - 1, acc * base
    }
  }
}

///|
fn repeat_list(items : Array[Value], times : Int) -> Array[Value] {
  if times <= 0 {
    []
  } else {
    items.repeat(times)
  }
}

///|
impl Eq for Value with equal(a : Value, b : Value) -> Bool {
  match (a, b) {
    (VInt(x), VInt(y)) => x == y
    (VBool(x), VBool(y)) => x == y
    (VString(x), VString(y)) => x == y
    (VNil, VNil) => true
    (VList(x), VList(y)) => x == y
    (VRecord(x), VRecord(y)) => x == y
    (VVariant(tag1, value1), VVariant(tag2, value2)) =>
      tag1 == tag2 && value1 == value2
    _ => false
  }
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
    StaticErrorAt(message, span) =>
      Some("\{message} at \{format_source_span(span, 0)}")
    RuntimeErrorAt(message, span) =>
      Some("\{message} at \{format_source_span(span, 0)}")
    _ => None
  } noraise {
    _ => None
  }
}
