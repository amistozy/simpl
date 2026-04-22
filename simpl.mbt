///|
/// Dynamic typed AST definitions
pub enum Expr {
  IntLit(Int)
  BoolLit(Bool)
  StringLit(String)
  NilLit
  List(Array[Expr])
  Var(String)
  Record(Array[(String, Expr)])
  Variant(String, Expr)
  If(Expr, Expr, Expr)
  Let(MatchPattern, Expr, Expr)
  Match(Expr, Array[(MatchPattern, Expr?, Expr)])
  LetRec(String, Array[MatchPattern], Expr, Expr)
  Lambda(Array[MatchPattern], Expr)
  Call(Expr, Array[Expr])
  RefNew(Expr)
  RefGet(Expr)
  RefSet(Expr, Expr)
  Field(Expr, String)
  Unary(UnOp, Expr)
  Binary(BinOp, Expr, Expr)
} derive(Debug)

///|
pub enum MatchPattern {
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
pub enum BinOp {
  Add
  Sub
  Mul
  Div
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
pub enum UnOp {
  Neg
  Not
} derive(Debug)

///|
/// Dynamic runtime values + environment model
pub enum Value {
  VInt(Int)
  VBool(Bool)
  VString(String)
  VNil
  VList(Array[Value])
  VRecord(@hashmap.HashMap[String, Value])
  VVariant(String, Value)
  VRef(@ref.Ref[Value])
  VClosure(Array[MatchPattern], Expr, Env)
  VRecClosure(String, Array[MatchPattern], Expr, Env)
} derive(Debug)

///|
pub type Env = @hashmap.HashMap[String, Value]

///|
pub suberror EvalError {
  RuntimeError(String)
} derive(Debug)

///|
/// Public API
pub fn eval(expr : Expr) -> Value raise {
  eval_with_env(expr, @hashmap.new())
}

///|
pub fn eval_with_env(expr : Expr, env : Env) -> Value raise {
  match expr {
    IntLit(v) => VInt(v)
    BoolLit(v) => VBool(v)
    StringLit(v) => VString(v)
    NilLit => VNil
    List(items) => VList(eval_expr_list(items, env))
    Var(name) => lookup(env, name)
    Record(fields) => VRecord(eval_record_fields(fields, env))
    Variant(tag, value_expr) => VVariant(tag, eval_with_env(value_expr, env))
    If(cond, then_branch, else_branch) =>
      if truthy(eval_with_env(cond, env)) {
        eval_with_env(then_branch, env)
      } else {
        eval_with_env(else_branch, env)
      }
    Let(pattern, value_expr, body) => {
      let v = eval_with_env(value_expr, env)
      let bound_env = bind_pattern(pattern, v, env)
      eval_with_env(body, bound_env)
    }
    Match(value_expr, cases) => {
      let value = eval_with_env(value_expr, env)
      eval_match_cases(value, cases, env, 0)
    }
    LetRec(name, params, func_body, body) => {
      let rec_closure = VRecClosure(name, params, func_body, env)
      eval_with_env(body, env.add(name, rec_closure))
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
        _ => raise RuntimeError("type error: '!' expects Ref")
      }
    RefSet(ref_expr, value_expr) => {
      let ref_value = eval_with_env(ref_expr, env)
      let new_value = eval_with_env(value_expr, env)
      match ref_value {
        VRef(cell) => {
          cell.val = new_value
          new_value
        }
        _ => raise RuntimeError("type error: ':=' expects Ref on left side")
      }
    }
    Field(target, name) => {
      let target_value = eval_with_env(target, env)
      match target_value {
        VRecord(fields) =>
          match fields.get(name) {
            Some(value) => value
            None => raise RuntimeError("missing field: \{name}")
          }
        _ => raise RuntimeError("type error: '.' expects Record")
      }
    }
    Unary(op, one) => eval_unary(op, eval_with_env(one, env))
    Binary(op, left, right) =>
      match op {
        And => {
          let left_value = eval_with_env(left, env)
          if truthy(left_value) {
            eval_with_env(right, env)
          } else {
            left_value
          }
        }
        Or => {
          let left_value = eval_with_env(left, env)
          if truthy(left_value) {
            left_value
          } else {
            eval_with_env(right, env)
          }
        }
        _ =>
          eval_binary(op, eval_with_env(left, env), eval_with_env(right, env))
      }
  }
}

///|
/// Helpers: environment and apply
fn lookup(env : Env, name : String) -> Value raise {
  match env.get(name) {
    Some(value) => value
    None => raise RuntimeError("undefined variable: \{name}")
  }
}

///|
fn apply(func_value : Value, args : Array[Value]) -> Value raise {
  match func_value {
    VClosure(params, body, closure_env) => {
      let call_env = bind_patterns(params, args, closure_env)
      eval_with_env(body, call_env)
    }
    VRecClosure(name, params, body, closure_env) => {
      let call_env = bind_patterns(params, args, closure_env).add(
        name, func_value,
      )
      eval_with_env(body, call_env)
    }
    _ => raise RuntimeError("attempt to call a non-function value")
  }
}

///|
fn bind_patterns(
  patterns : Array[MatchPattern],
  args : Array[Value],
  base : Env,
) -> Env raise {
  if patterns.length() < args.length() {
    raise RuntimeError("too many arguments")
  }
  if patterns.length() > args.length() {
    raise RuntimeError("too few arguments")
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
fn eval_match_cases(
  value : Value,
  cases : Array[(MatchPattern, Expr?, Expr)],
  env : Env,
  i : Int,
) -> Value raise {
  if i >= cases.length() {
    match value {
      VVariant(tag, _) =>
        raise RuntimeError("non-exhaustive match on variant: " + tag)
      VList(_) => raise RuntimeError("non-exhaustive match on list")
      VRecord(_) => raise RuntimeError("non-exhaustive match on record")
      _ => raise RuntimeError("non-exhaustive match")
    }
  }
  let (pattern, cond_expr, body) = cases[i]
  match try_bind_pattern(pattern, value, env) {
    Some(bound_env) =>
      if match_guard_passes(cond_expr, bound_env) {
        eval_with_env(body, bound_env)
      } else {
        eval_match_cases(value, cases, env, i + 1)
      }
    None => eval_match_cases(value, cases, env, i + 1)
  }
}

///|
fn match_guard_passes(cond_expr : Expr?, env : Env) -> Bool raise {
  match cond_expr {
    Some(cond) => truthy(eval_with_env(cond, env))
    None => true
  }
}

///|
fn bind_pattern(pattern : MatchPattern, value : Value, env : Env) -> Env raise {
  match try_bind_pattern(pattern, value, env) {
    Some(bound_env) => bound_env
    None => raise RuntimeError("pattern match failure")
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
fn eval_unary(op : UnOp, value : Value) -> Value raise {
  match op {
    Neg =>
      match value {
        VInt(v) => VInt(-v)
        _ => raise RuntimeError("type error: unary '-' expects Int")
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
          raise RuntimeError("type error: '+' expects Int+Int or String+String")
      }
    Sub =>
      match (left, right) {
        (VInt(a), VInt(b)) => VInt(a - b)
        _ => raise RuntimeError("type error: '-' expects Int+Int")
      }
    Mul =>
      match (left, right) {
        (VInt(a), VInt(b)) => VInt(a * b)
        _ => raise RuntimeError("type error: '*' expects Int+Int")
      }
    Div =>
      match (left, right) {
        (VInt(_), VInt(0)) => raise RuntimeError("division by zero")
        (VInt(a), VInt(b)) => VInt(a / b)
        _ => raise RuntimeError("type error: '/' expects Int+Int")
      }
    Eq => VBool(value_eq(left, right))
    Ne => VBool(!value_eq(left, right))
    Lt =>
      match (left, right) {
        (VInt(a), VInt(b)) => VBool(a < b)
        _ => raise RuntimeError("type error: '<' expects Int+Int")
      }
    Le =>
      match (left, right) {
        (VInt(a), VInt(b)) => VBool(a <= b)
        _ => raise RuntimeError("type error: '<=' expects Int+Int")
      }
    Gt =>
      match (left, right) {
        (VInt(a), VInt(b)) => VBool(a > b)
        _ => raise RuntimeError("type error: '>' expects Int+Int")
      }
    Ge =>
      match (left, right) {
        (VInt(a), VInt(b)) => VBool(a >= b)
        _ => raise RuntimeError("type error: '>=' expects Int+Int")
      }
    And => if truthy(left) { right } else { left }
    Or => if truthy(left) { left } else { right }
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
/// Constructors for users and tests
pub fn int_lit(v : Int) -> Expr {
  IntLit(v)
}

///|
pub fn bool_lit(v : Bool) -> Expr {
  BoolLit(v)
}

///|
pub fn string_lit(v : String) -> Expr {
  StringLit(v)
}

///|
pub fn nil_lit() -> Expr {
  NilLit
}

///|
pub fn list(items : Array[Expr]) -> Expr {
  List(items)
}

///|
pub fn var_ref(name : String) -> Expr {
  Var(name)
}

///|
pub fn record(fields : Array[(String, Expr)]) -> Expr {
  Record(fields)
}

///|
pub fn variant(tag : String, value : Expr) -> Expr {
  Variant(tag, value)
}

///|
pub fn if_then_else(
  cond : Expr,
  then_branch : Expr,
  else_branch : Expr,
) -> Expr {
  If(cond, then_branch, else_branch)
}

///|
pub fn let_in(name : String, value_expr : Expr, body : Expr) -> Expr {
  Let(PBind(name), value_expr, body)
}

///|
pub fn let_pattern_in(
  pattern : MatchPattern,
  value_expr : Expr,
  body : Expr,
) -> Expr {
  Let(pattern, value_expr, body)
}

///|
pub fn let_record_in(
  bindings : Array[(String, String)],
  value_expr : Expr,
  body : Expr,
) -> Expr {
  let_pattern_in(
    PRecord(
      bindings.map(binding => {
        let (field_name, local_name) = binding
        (field_name, PBind(local_name))
      }),
    ),
    value_expr,
    body,
  )
}

///|
pub fn match_variant(
  value_expr : Expr,
  cases : Array[(String, String, Expr)],
) -> Expr {
  match_case_clauses(
    value_expr,
    cases.map((case : (String, String, Expr)) => {
      let (tag, binding, body) = case
      (PVariant(tag, PBind(binding)), None, body)
    }),
  )
}

///|
pub fn match_list(
  value_expr : Expr,
  cases : Array[(Array[String], Expr)],
) -> Expr {
  match_case_clauses(
    value_expr,
    cases.map((case : (Array[String], Expr)) => {
      let (bindings, body) = case
      (PList(bindings.map(name => PBind(name))), None, body)
    }),
  )
}

///|
pub fn match_cases(
  value_expr : Expr,
  cases : Array[(MatchPattern, Expr)],
) -> Expr {
  match_case_clauses(
    value_expr,
    cases.map((case : (MatchPattern, Expr)) => {
      let (pattern, body) = case
      (pattern, None, body)
    }),
  )
}

///|
pub fn match_case_clauses(
  value_expr : Expr,
  cases : Array[(MatchPattern, Expr?, Expr)],
) -> Expr {
  Match(value_expr, cases)
}

///|
pub fn pbind(name : String) -> MatchPattern {
  PBind(name)
}

///|
pub fn pint(value : Int) -> MatchPattern {
  PInt(value)
}

///|
pub fn pbool(value : Bool) -> MatchPattern {
  PBool(value)
}

///|
pub fn pstring(value : String) -> MatchPattern {
  PString(value)
}

///|
pub fn pnil() -> MatchPattern {
  PNil
}

///|
pub fn por(patterns : Array[MatchPattern]) -> MatchPattern {
  POr(patterns)
}

///|
pub fn pvariant(tag : String, pattern : MatchPattern) -> MatchPattern {
  PVariant(tag, pattern)
}

///|
pub fn plist(items : Array[MatchPattern]) -> MatchPattern {
  PList(items)
}

///|
pub fn plist_rest(
  prefix : Array[MatchPattern],
  rest_name : String,
  suffix : Array[MatchPattern],
) -> MatchPattern {
  PListRest(prefix, rest_name, suffix)
}

///|
pub fn precord(fields : Array[(String, MatchPattern)]) -> MatchPattern {
  PRecord(fields)
}

///|
pub fn let_rec_in(
  name : String,
  params : Array[String],
  func_body : Expr,
  body : Expr,
) -> Expr {
  LetRec(name, params.map(name => PBind(name)), func_body, body)
}

///|
pub fn lambda(params : Array[String], body : Expr) -> Expr {
  Lambda(params.map(name => PBind(name)), body)
}

///|
pub fn lambda_patterns(params : Array[MatchPattern], body : Expr) -> Expr {
  Lambda(params, body)
}

///|
pub fn let_rec_patterns_in(
  name : String,
  params : Array[MatchPattern],
  func_body : Expr,
  body : Expr,
) -> Expr {
  LetRec(name, params, func_body, body)
}

///|
pub fn call(func : Expr, args : Array[Expr]) -> Expr {
  Call(func, args)
}

///|
pub fn ref_new(inner : Expr) -> Expr {
  RefNew(inner)
}

///|
pub fn ref_get(inner : Expr) -> Expr {
  RefGet(inner)
}

///|
pub fn ref_set(ref_expr : Expr, value_expr : Expr) -> Expr {
  RefSet(ref_expr, value_expr)
}

///|
pub fn field(target : Expr, name : String) -> Expr {
  Field(target, name)
}

///|
pub fn unary(op : UnOp, one : Expr) -> Expr {
  Unary(op, one)
}

///|
pub fn binary(op : BinOp, left : Expr, right : Expr) -> Expr {
  Binary(op, left, right)
}

///|
pub fn add(left : Expr, right : Expr) -> Expr {
  Binary(Add, left, right)
}

///|
pub fn sub(left : Expr, right : Expr) -> Expr {
  Binary(Sub, left, right)
}

///|
pub fn mul(left : Expr, right : Expr) -> Expr {
  Binary(Mul, left, right)
}

///|
pub fn div(left : Expr, right : Expr) -> Expr {
  Binary(Div, left, right)
}

///|
pub fn eq(left : Expr, right : Expr) -> Expr {
  Binary(Eq, left, right)
}

///|
pub fn ne(left : Expr, right : Expr) -> Expr {
  Binary(Ne, left, right)
}

///|
pub fn lt(left : Expr, right : Expr) -> Expr {
  Binary(Lt, left, right)
}

///|
pub fn le(left : Expr, right : Expr) -> Expr {
  Binary(Le, left, right)
}

///|
pub fn gt(left : Expr, right : Expr) -> Expr {
  Binary(Gt, left, right)
}

///|
pub fn ge(left : Expr, right : Expr) -> Expr {
  Binary(Ge, left, right)
}

///|
pub fn logic_and(left : Expr, right : Expr) -> Expr {
  Binary(And, left, right)
}

///|
pub fn logic_or(left : Expr, right : Expr) -> Expr {
  Binary(Or, left, right)
}

///|
pub fn neg(one : Expr) -> Expr {
  Unary(Neg, one)
}

///|
pub fn not(one : Expr) -> Expr {
  Unary(Not, one)
}

///|
pub fn eval_is_int(expr : Expr, expected : Int) -> Bool {
  try eval(expr) catch {
    _ => false
  } noraise {
    VInt(v) => v == expected
    _ => false
  }
}

///|
pub fn eval_is_bool(expr : Expr, expected : Bool) -> Bool {
  try eval(expr) catch {
    _ => false
  } noraise {
    VBool(v) => v == expected
    _ => false
  }
}

///|
pub fn eval_is_string(expr : Expr, expected : String) -> Bool {
  try eval(expr) catch {
    _ => false
  } noraise {
    VString(v) => v == expected
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
pub fn eval_is_error(expr : Expr) -> Bool {
  try eval(expr) catch {
    _ => true
  } noraise {
    _ => false
  }
}
