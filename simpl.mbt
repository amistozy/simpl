///|
/// Dynamic typed AST definitions
pub enum Expr {
  IntLit(Int)
  BoolLit(Bool)
  StringLit(String)
  NilLit
  Var(String)
  If(Expr, Expr, Expr)
  Let(String, Expr, Expr)
  Lambda(@list.List[String], Expr)
  Call(Expr, @list.List[Expr])
  Unary(UnOp, Expr)
  Binary(BinOp, Expr, Expr)
}

///|
pub enum BinOp {
  Add
  Sub
  Mul
  Div
  Eq
  Lt
  Gt
  And
  Or
}

///|
pub enum UnOp {
  Neg
  Not
}

///|
/// Dynamic runtime values + environment model
pub enum Value {
  VInt(Int)
  VBool(Bool)
  VString(String)
  VNil
  VClosure(@list.List[String], Expr, Env)
}

///|
pub type Env = @hashmap.HashMap[String, Value]

///|
pub suberror EvalError {
  RuntimeError(String)
}

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
    Var(name) => lookup(env, name)
    If(cond, then_branch, else_branch) =>
      if truthy(eval_with_env(cond, env)) {
        eval_with_env(then_branch, env)
      } else {
        eval_with_env(else_branch, env)
      }
    Let(name, value_expr, body) => {
      let v = eval_with_env(value_expr, env)
      eval_with_env(body, env.add(name, v))
    }
    Lambda(params, body) => VClosure(params, body, env)
    Call(func_expr, arg_exprs) => {
      let func_value = eval_with_env(func_expr, env)
      let args = eval_expr_list(arg_exprs, env)
      apply(func_value, args)
    }
    Unary(op, one) => eval_unary(op, eval_with_env(one, env))
    Binary(op, left, right) =>
      eval_binary(op, eval_with_env(left, env), eval_with_env(right, env))
  }
}

///|
/// Helpers: environment and apply
fn lookup(env : Env, name : String) -> Value raise {
  match env.get(name) {
    Some(value) => value
    None => raise RuntimeError("undefined variable: " + name)
  }
}

///|
fn apply(func_value : Value, args : @list.List[Value]) -> Value raise {
  match func_value {
    VClosure(params, body, closure_env) => {
      let call_env = bind_params(params, args, closure_env)
      eval_with_env(body, call_env)
    }
    _ => raise RuntimeError("attempt to call a non-function value")
  }
}

///|
fn bind_params(
  params : @list.List[String],
  args : @list.List[Value],
  base : Env,
) -> Env raise {
  match (params, args) {
    (@list.Empty, @list.Empty) => base
    (@list.Empty, More(_, tail=_)) => raise RuntimeError("too many arguments")
    (More(_, tail=_), @list.Empty) => raise RuntimeError("too few arguments")
    (More(name, tail=rest_params), More(value, tail=rest_args)) =>
      bind_params(rest_params, rest_args, base.add(name, value))
  }
}

///|
/// Helpers: expression list evaluation
fn eval_expr_list(
  exprs : @list.List[Expr],
  env : Env,
) -> @list.List[Value] raise {
  match exprs {
    @list.Empty => @list.empty()
    More(head, tail~) => {
      let head_value = eval_with_env(head, env)
      let values_tail = eval_expr_list(tail, env)
      @list.cons(head_value, values_tail)
    }
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
    Lt =>
      match (left, right) {
        (VInt(a), VInt(b)) => VBool(a < b)
        _ => raise RuntimeError("type error: '<' expects Int+Int")
      }
    Gt =>
      match (left, right) {
        (VInt(a), VInt(b)) => VBool(a > b)
        _ => raise RuntimeError("type error: '>' expects Int+Int")
      }
    And => VBool(truthy(left) && truthy(right))
    Or => VBool(truthy(left) || truthy(right))
  }
}

///|
fn value_eq(a : Value, b : Value) -> Bool {
  match (a, b) {
    (VInt(x), VInt(y)) => x == y
    (VBool(x), VBool(y)) => x == y
    (VString(x), VString(y)) => x == y
    (VNil, VNil) => true
    _ => false
  }
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
pub fn var_ref(name : String) -> Expr {
  Var(name)
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
  Let(name, value_expr, body)
}

///|
pub fn lambda(params : @list.List[String], body : Expr) -> Expr {
  Lambda(params, body)
}

///|
pub fn call(func : Expr, args : @list.List[Expr]) -> Expr {
  Call(func, args)
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
pub fn lt(left : Expr, right : Expr) -> Expr {
  Binary(Lt, left, right)
}

///|
pub fn gt(left : Expr, right : Expr) -> Expr {
  Binary(Gt, left, right)
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
pub fn eval_is_error(expr : Expr) -> Bool {
  try eval(expr) catch {
    _ => true
  } noraise {
    _ => false
  }
}

///|
pub fn strings0() -> @list.List[String] {
  @list.empty()
}

///|
pub fn strings1(a : String) -> @list.List[String] {
  @list.from_array([a])
}

///|
pub fn strings2(a : String, b : String) -> @list.List[String] {
  @list.from_array([a, b])
}

///|
pub fn exprs0() -> @list.List[Expr] {
  @list.empty()
}

///|
pub fn exprs1(a : Expr) -> @list.List[Expr] {
  @list.from_array([a])
}

///|
pub fn exprs2(a : Expr, b : Expr) -> @list.List[Expr] {
  @list.from_array([a, b])
}
