///|
/// Dynamic typed AST definitions
pub enum Expr {
  Located(SourceSpan, Expr)
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
  Is(Expr, MatchPattern)
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
  RuntimeErrorAt(String, SourceSpan)
} derive(Debug)

///|
/// Public API
pub fn eval(expr : Expr) -> Value raise {
  eval_with_env(expr, @hashmap.new())
}

///|
pub fn format_eval_error(error : EvalError) -> String {
  match error {
    RuntimeErrorAt(message, span) => message + " at " + format_source_span(span)
  }
}

///|
pub fn eval_with_env(expr : Expr, env : Env) -> Value raise {
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
    If(cond, then_branch, else_branch) => {
      let (passes, then_env) = eval_condition_bindings(cond, env)
      if passes {
        eval_with_env(then_branch, then_env)
      } else {
        eval_with_env(else_branch, env)
      }
    }
    Let(pattern, value_expr, body) => {
      let v = eval_with_env(value_expr, env)
      let bound_env = bind_pattern(pattern, v, env)
      eval_with_env(body, bound_env)
    }
    Is(value_expr, pattern) =>
      VBool(
        try_bind_pattern(pattern, eval_with_env(value_expr, env), env)
        is Some(_),
      )
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
          raise type_error_unary("operator ':='", "Ref on left side", value)
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
    Is(value_expr, pattern) =>
      match try_bind_pattern(pattern, eval_with_env(value_expr, env), env) {
        Some(bound_env) => (VBool(true), bound_env)
        None => (VBool(false), env)
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
/// Helpers: environment and apply
fn lookup(env : Env, name : String) -> Value raise {
  match env.get(name) {
    Some(value) => value
    None => raise undefined_variable_error(name)
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
fn eval_match_cases(
  value : Value,
  cases : Array[(MatchPattern, Expr?, Expr)],
  env : Env,
  i : Int,
) -> Value raise {
  if i >= cases.length() {
    raise runtime_error(
      "non-exhaustive match: no case matched value " + value_summary(value),
    )
  }
  let (pattern, cond_expr, body) = cases[i]
  match try_bind_pattern(pattern, value, env) {
    Some(bound_env) => {
      let (passes, guard_env) = eval_match_guard(cond_expr, bound_env)
      if passes {
        eval_with_env(body, guard_env)
      } else {
        eval_match_cases(value, cases, env, i + 1)
      }
    }
    None => eval_match_cases(value, cases, env, i + 1)
  }
}

///|
fn eval_match_guard(cond_expr : Expr?, env : Env) -> (Bool, Env) raise {
  match cond_expr {
    Some(cond) => eval_condition_bindings(cond, env)
    None => (true, env)
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
    VRecClosure(_, _, _, _) => "function"
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
    VRecClosure(_, _, _, _) => "Function"
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
        (VInt(_), VInt(0)) => raise runtime_error("division by zero")
        (VInt(a), VInt(b)) => VInt(a / b)
        _ => raise type_error_binary("operator '/'", "(Int, Int)", left, right)
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
pub fn is_expr(value_expr : Expr, pattern : MatchPattern) -> Expr {
  Is(value_expr, pattern)
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
