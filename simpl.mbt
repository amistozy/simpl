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
  SLetFun(String, Array[SurfaceParam], SurfaceExpr, SurfaceExpr)
  SLetRec(String, Array[SurfaceParam], SurfaceExpr, SurfaceExpr)
  SLetRecAnd(Array[(String, Array[SurfaceParam], SurfaceExpr)], SurfaceExpr)
  SWith(Array[SurfaceParam], SurfaceExpr, SurfaceExpr)
  STrailingCall(SurfaceExpr, SurfaceExpr)
  SLambda(Array[SurfaceParam], SurfaceExpr)
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
  LetRec(String, Array[Param], Expr, Expr)
  LetRecAnd(Array[(String, Array[Param], Expr)], Expr)
  Lambda(Array[Param], Expr)
  Call(Expr, Array[CallArg])
  Field(Expr, String)
  Unary(UnOp, Expr)
  Binary(BinOp, Expr, Expr)
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
  VRef(@ref.Ref[Value])
  VClosure(Array[Param], Expr, Env, Array[Value?])
  VRecClosure(
    String,
    Array[Param],
    Expr,
    Env,
    Array[(String, Array[Param], Expr)],
    Array[Value?]
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
fn surface_expr_pretty(expr : SurfaceExpr) -> String {
  match expr {
    SLocated(_, inner) => surface_expr_pretty(inner)
    SIntLit(v) => v.to_string()
    SBoolLit(v) => v.to_string()
    SStringLit(v) => "\"\{v}\""
    SNilLit => "nil"
    SList(items) => "[\{surface_expr_list_pretty(items)}]"
    SVar(name) => name
    SRecord(fields) => "{\{surface_record_fields_pretty(fields)}}"
    SVariant(tag, value_expr) => "#\{tag}(\{surface_expr_pretty(value_expr)})"
    SIf(cases, else_expr) =>
      "if \{surface_if_cond_arms_pretty(cases)} else \{surface_expr_pretty(else_expr)} end"
    SLet(pattern, value_expr, body) =>
      "let \{surface_pattern_pretty(pattern)} = \{surface_expr_pretty(value_expr)}; \{surface_expr_pretty(body)}"
    SLetAnd(bindings, body) =>
      "let \{surface_let_bindings_pretty(bindings)}; \{surface_expr_pretty(body)}"
    SDo(value_expr, body) =>
      "do \{surface_expr_pretty(value_expr)}; \{surface_expr_pretty(body)}"
    SLetFun(name, params, func_body, body) =>
      "let \{name}(\{surface_param_list_pretty(params)}) = \{surface_expr_pretty(func_body)}; \{surface_expr_pretty(body)}"
    SLetRec(name, params, func_body, body) =>
      "let rec \{name}(\{surface_param_list_pretty(params)}) = \{surface_expr_pretty(func_body)}; \{surface_expr_pretty(body)}"
    SLetRecAnd(defs, body) =>
      "let rec \{surface_let_rec_defs_pretty(defs)}; \{surface_expr_pretty(body)}"
    SWith(params, target_expr, body) =>
      "with(\{surface_param_list_pretty(params)}) = \{surface_expr_pretty(target_expr)}; \{surface_expr_pretty(body)}"
    STrailingCall(func_expr, arg_expr) =>
      "\{surface_expr_pretty(func_expr)} \{surface_expr_pretty(arg_expr)}"
    SLambda(params, body) =>
      "fn(\{surface_param_list_pretty(params)}) = \{surface_expr_pretty(body)}"
    SCall(func_expr, arg_exprs) =>
      "\{surface_expr_pretty(func_expr)}(\{surface_call_arg_list_pretty(arg_exprs)})"
    SField(target, name) => "\{surface_expr_pretty(target)}.\{name}"
    SUnary(op, one) => "\{surface_unary_op_text(op)}\{surface_expr_pretty(one)}"
    SBinary(op, left, right) =>
      "(\{surface_expr_pretty(left)} \{surface_bin_op_text(op)} \{surface_expr_pretty(right)})"
  }
}

///|
fn surface_expr_list_pretty(items : Array[SurfaceExpr]) -> String {
  items.map(surface_expr_pretty).join("; ")
}

///|
fn surface_param_pretty(param : SurfaceParam) -> String {
  match param {
    SParam(pattern, default_expr) =>
      match default_expr {
        Some(expr) =>
          "\{surface_pattern_pretty(pattern)} = \{surface_expr_pretty(expr)}"
        None => surface_pattern_pretty(pattern)
      }
  }
}

///|
fn surface_param_list_pretty(params : Array[SurfaceParam]) -> String {
  params.map(surface_param_pretty).join("; ")
}

///|
fn surface_call_arg_pretty(arg : SurfaceCallArg) -> String {
  match arg {
    SArgPos(expr) => surface_expr_pretty(expr)
    SArgNamed(name, value_expr) =>
      "\{name} = \{surface_expr_pretty(value_expr)}"
  }
}

///|
fn surface_call_arg_list_pretty(args : Array[SurfaceCallArg]) -> String {
  args.map(surface_call_arg_pretty).join("; ")
}

///|
fn surface_record_fields_pretty(fields : Array[SurfaceRecordField]) -> String {
  fields
  .map(field => {
    match field {
      SRecordField(name, value_expr) =>
        "\{name} = \{surface_expr_pretty(value_expr)}"
      SRecordShorthand(name) => name
    }
  })
  .join("; ")
}

///|
fn surface_if_cond_arms_pretty(arms : Array[SurfaceIfCondArm]) -> String {
  arms
  .map(arm => {
    match arm {
      SIfCondArm(cond, arm_guard) =>
        "\{surface_expr_pretty(cond)} \{surface_if_guard_pretty(arm_guard)}"
    }
  })
  .join(" | ")
}

///|
fn surface_if_pattern_arms_pretty(arms : Array[SurfaceIfPatternArm]) -> String {
  arms
  .map(arm => {
    match arm {
      SIfPatternArm(pattern, arm_guard) =>
        "\{surface_pattern_pretty(pattern)} \{surface_if_guard_pretty(arm_guard)}"
    }
  })
  .join(" | ")
}

///|
fn surface_if_guard_pretty(arm_guard : SurfaceIfGuard) -> String {
  match arm_guard {
    SIfThen(body) => "then \{surface_expr_pretty(body)}"
    SIfAnd(arms) => "and (\{surface_if_cond_arms_pretty(arms)})"
    SIfIs(value_expr, pattern_arms) =>
      "is \{surface_expr_pretty(value_expr)} (\{surface_if_pattern_arms_pretty(pattern_arms)})"
  }
}

///|
fn surface_pattern_pretty(pattern : SurfacePattern) -> String {
  match pattern {
    SPBind(name) => name
    SPInt(v) => v.to_string()
    SPBool(v) => v.to_string()
    SPString(v) => "\"\{v}\""
    SPNil => "nil"
    SPOr(patterns) => surface_pattern_or_pretty(patterns)
    SPVariant(tag, inner) => "#\{tag}(\{surface_pattern_pretty(inner)})"
    SPList(items) => "[\{surface_pattern_list_pretty(items)}]"
    SPListRest(prefix, rest_name, suffix) =>
      "[\{surface_list_rest_pretty(prefix, rest_name, suffix)}]"
    SPRecord(fields) => "{\{surface_record_pattern_fields_pretty(fields)}}"
  }
}

///|
fn surface_pattern_or_pretty(patterns : Array[SurfacePattern]) -> String {
  patterns.map(surface_pattern_pretty).join(" | ")
}

///|
fn surface_pattern_list_pretty(patterns : Array[SurfacePattern]) -> String {
  patterns.map(surface_pattern_pretty).join("; ")
}

///|
fn surface_record_pattern_fields_pretty(
  fields : Array[SurfaceRecordPatternField],
) -> String {
  fields
  .map(field => {
    match field {
      SPRecordField(name, pattern) =>
        "\{name} = \{surface_pattern_pretty(pattern)}"
      SPRecordShorthand(name) => name
    }
  })
  .join("; ")
}

///|
fn surface_list_rest_pretty(
  prefix : Array[SurfacePattern],
  rest_name : String,
  suffix : Array[SurfacePattern],
) -> String {
  let prefix_text = surface_pattern_list_pretty(prefix)
  let suffix_text = surface_pattern_list_pretty(suffix)
  if prefix.length() == 0 && suffix.length() == 0 {
    "..\{rest_name}"
  } else if prefix.length() == 0 {
    "..\{rest_name}; \{suffix_text}"
  } else if suffix.length() == 0 {
    "\{prefix_text}; ..\{rest_name}"
  } else {
    "\{prefix_text}; ..\{rest_name}; \{suffix_text}"
  }
}

///|
fn surface_let_bindings_pretty(
  bindings : Array[(SurfacePattern, SurfaceExpr)],
) -> String {
  bindings
  .map(binding => {
    let (pattern, value_expr) = binding
    "\{surface_pattern_pretty(pattern)} = \{surface_expr_pretty(value_expr)}"
  })
  .join(" and ")
}

///|
fn surface_let_rec_defs_pretty(
  defs : Array[(String, Array[SurfaceParam], SurfaceExpr)],
) -> String {
  defs
  .map(def => {
    let (name, params, func_body) = def
    "\{name}(\{surface_param_list_pretty(params)}) = \{surface_expr_pretty(func_body)}"
  })
  .join(" and ")
}

///|
fn surface_bin_op_text(op : BinOp) -> String {
  match op {
    Add => "+"
    Sub => "-"
    Mul => "*"
    Div => "/"
    Mod => "%"
    Eq => "=="
    Ne => "!="
    Lt => "<"
    Le => "<="
    Gt => ">"
    Ge => ">="
    And => "&&"
    Or => "||"
    RefSet => ":="
    RefUpdateAdd => "+="
    RefUpdateSub => "-="
    RefUpdateMul => "*="
    RefUpdateDiv => "/="
    RefUpdateMod => "%="
    RefUpdateAnd => "&&="
    RefUpdateOr => "||="
  }
}

///|
fn surface_unary_op_text(op : UnOp) -> String {
  match op {
    Neg => "-"
    Bang => "!"
    Dollar => "$"
  }
}

///|
fn value_pretty(value : Value, depth : Int) -> String {
  if depth <= 0 {
    return "..."
  }
  match value {
    VInt(v) => v.to_string()
    VBool(v) => v.to_string()
    VString(v) => "\"\{v}\""
    VNil => "nil"
    VList(items) => "[\{value_list_pretty(items, depth - 1)}]"
    VRecord(fields) => "{\{value_record_pretty(fields, depth - 1)}}"
    VVariant(tag, payload) => "#\{tag}(\{value_pretty(payload, depth - 1)})"
    VRef(cell) => "ref(\{value_pretty(cell.val, depth - 1)})"
    VClosure(_) => "<fn>"
    VRecClosure(name, _, _, _, _, _) => "<rec \{name}>"
    VBuiltin(builtin) => "<builtin \{builtin_name(builtin)}>"
  }
}

///|
fn value_list_pretty(values : Array[Value], depth : Int) -> String {
  values.map(value => value_pretty(value, depth)).join("; ")
}

///|
fn value_record_pretty(
  fields : @hashmap.HashMap[String, Value],
  depth : Int,
) -> String {
  fields.fold(init="", (acc, name, value) => {
    let current = "\{name} = \{value_pretty(value, depth)}"
    if acc == "" {
      current
    } else {
      "\{acc}; \{current}"
    }
  })
}

///|
/// Public API
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
  [("ref", BRef), ("say", BSay), ("map", BMap)]
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
    Lambda(params, body) => {
      let defaults = eval_param_defaults(params, env)
      VClosure(params, body, env, defaults)
    }
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
        RefSet
        | RefUpdateAdd
        | RefUpdateSub
        | RefUpdateMul
        | RefUpdateDiv
        | RefUpdateMod
        | RefUpdateAnd
        | RefUpdateOr => eval_ref_binop(op, left, right, env)
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
fn eval_ref_binop(
  op : BinOp,
  left : Expr,
  right : Expr,
  env : Env,
) -> Value raise {
  let left_value = eval_with_env(left, env)
  match left_value {
    VRef(cell) => {
      let old_value = cell.val
      let new_value = match op {
        RefSet => eval_with_env(right, env)
        RefUpdateAdd
        | RefUpdateSub
        | RefUpdateMul
        | RefUpdateDiv
        | RefUpdateMod => {
          let right_value = eval_with_env(right, env)
          eval_binary(ref_update_to_base_binop(op), old_value, right_value)
        }
        RefUpdateAnd =>
          if truthy(old_value) {
            eval_with_env(right, env)
          } else {
            old_value
          }
        RefUpdateOr =>
          if truthy(old_value) {
            old_value
          } else {
            eval_with_env(right, env)
          }
        _ => runtime_error("invalid ref binary operator")
      }
      cell.val = new_value
      new_value
    }
    value =>
      type_error_unary(ref_binary_operator_text(op), "Ref on left side", value)
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
  let (passes, base_env) = eval_condition_bindings(cond, env)
  guard passes else {
    eval_if_cond_arms_with_fallback(arms, fallback, env, i + 1)
  }
  guard eval_if_guard(arm_guard, base_env) is Some(result) else {
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
) -> Env raise {
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
) -> Value raise {
  let (name, params, body) = def
  let defaults = eval_param_defaults(params, closure_env)
  VRecClosure(name, params, body, closure_env, defs, defaults)
}

///|
priv enum EvaluatedCallArg {
  EArgPos(Value)
  EArgNamed(String, Value)
}

///|
fn apply(func_value : Value, args : Array[EvaluatedCallArg]) -> Value raise {
  match func_value {
    VInt(times) => apply_int_call(times, args)
    VList(items) => apply_list_call(items, args)
    VString(prefix_or_sep) => apply_string_call(prefix_or_sep, args)
    VRecord(fields) => apply_record_with_named_args(fields, args)
    VClosure(params, body, closure_env, default_values) => {
      let call_env = bind_params(params, args, closure_env, default_values)
      eval_with_env(body, call_env)
    }
    VRecClosure(_, params, body, closure_env, defs, default_values) => {
      let call_base_env = build_rec_env(defs, closure_env)
      let call_env = bind_params(params, args, call_base_env, default_values)
      eval_with_env(body, call_env)
    }
    VBuiltin(builtin) => apply_builtin(builtin, args)
    _ => call_non_function_error(func_value)
  }
}

///|
fn apply_list_call(
  items : Array[Value],
  args : Array[EvaluatedCallArg],
) -> Value raise {
  guard args.length() == 1 else { arity_error(1, args.length()) }
  guard args is [EArgPos(func_value)] else {
    runtime_error("list call only accepts positional arguments")
  }
  guard value_is_function(func_value) else {
    runtime_error(
      "list call expected Function, got \{typed_value_summary(func_value)}",
    )
  }
  guard function_param_count(func_value) is Some(param_count) else {
    runtime_error(
      "list call expected Function, got \{typed_value_summary(func_value)}",
    )
  }
  guard param_count == 1 else {
    runtime_error("list call function expected 1 parameter, got \{param_count}")
  }

  let acc = []
  for item in items {
    append_result(acc, apply(func_value, [EArgPos(item)]))
  }
  VList(acc)
}

///|
fn apply_int_call(times : Int, args : Array[EvaluatedCallArg]) -> Value raise {
  guard args.length() == 1 else { arity_error(1, args.length()) }
  guard args is [EArgPos(value)] else {
    runtime_error("int call only accepts positional arguments")
  }
  match value {
    VString(text) => VString(text.repeat(times))
    VList(items) => VList(repeat_list(items, times))
    _ => {
      guard value_is_function(value) else {
        runtime_error(
          "int call expected String, List, or Function, got \{typed_value_summary(value)}",
        )
      }
      guard function_param_count(value) is Some(param_count) else {
        runtime_error(
          "int call expected String, List, or Function, got \{typed_value_summary(value)}",
        )
      }
      if times <= 0 {
        VList([])
      } else if param_count == 0 {
        VList(repeat_function_results(value, times, false))
      } else if param_count == 1 {
        VList(repeat_function_results(value, times, true))
      } else {
        runtime_error(
          "int call function expected 0 or 1 parameter, got \{param_count}",
        )
      }
    }
  }
}

///|
fn repeat_function_results(
  func_value : Value,
  times : Int,
  pass_index : Bool,
) -> Array[Value] raise {
  let acc = []
  if pass_index {
    for i in 0..<times {
      append_result(acc, apply(func_value, [EArgPos(VInt(i))]))
    }
  } else {
    for _ in 0..<times {
      append_result(acc, apply(func_value, []))
    }
  }
  acc
}

///|
fn append_result(acc : Array[Value], result : Value) -> Unit {
  match result {
    VNil => ()
    VList(items) => acc.append(items)
    _ => acc.push(result)
  }
}

///|
fn apply_string_call(
  text : String,
  args : Array[EvaluatedCallArg],
) -> Value raise {
  guard args.length() == 1 else { arity_error(1, args.length()) }
  guard args is [EArgPos(value)] else {
    runtime_error("string call only accepts positional arguments")
  }
  match value {
    VString(suffix) => VString(text + suffix)
    VList(items) => VString(join_values_with_separator(items, text))
    _ =>
      runtime_error(
        "string call expected String or List, got \{typed_value_summary(value)}",
      )
  }
}

///|
fn join_values_with_separator(
  items : Array[Value],
  separator : String,
) -> String {
  items
  .map(item => {
    match item {
      VString(text) => text
      value => value_pretty(value, 6)
    }
  })
  .join(separator)
}

///|
fn apply_record_with_named_args(
  fields : @hashmap.HashMap[String, Value],
  args : Array[EvaluatedCallArg],
) -> Value raise {
  VRecord <| args.foldi(init=fields, (i, fields, arg) => {
    guard arg is EArgNamed(name, value) else {
      runtime_error("record call only accepts named arguments")
    }
    guard !record_call_has_duplicate_named_arg(args, name, i, 0) else {
      runtime_error("duplicate argument: \{name}")
    }
    fields.add(name, value)
  })
}

///|
fn record_call_has_duplicate_named_arg(
  args : Array[EvaluatedCallArg],
  name : String,
  limit_i : Int,
  j : Int,
) -> Bool {
  guard j < limit_i else { false }
  match args[j] {
    EArgNamed(n, _) if n == name => true
    _ => record_call_has_duplicate_named_arg(args, name, limit_i, j + 1)
  }
}

///|
fn apply_builtin(
  builtin : Builtin,
  args : Array[EvaluatedCallArg],
) -> Value raise {
  match builtin {
    BMap => {
      guard args.length() == 2 else { arity_error(2, args.length()) }
      guard args is [EArgPos(list_value), EArgPos(func_value)] else {
        builtin_named_arg_error(builtin)
      }
      guard list_value is VList(items) else {
        builtin_type_error("map", "List", list_value)
      }
      guard value_is_function(func_value) else {
        builtin_type_error("map", "Function", func_value)
      }
      VList(items.map(item => apply(func_value, [EArgPos(item)])))
    }
    _ => {
      guard args.length() == 1 else { arity_error(1, args.length()) }
      guard args is [EArgPos(v)] else { builtin_named_arg_error(builtin) }
      match builtin {
        BRef => VRef(@ref.new(v))
        BSay => {
          match v {
            VString(text) => println(text)
            _ => println(v)
          }
          VNil
        }
        _ => runtime_error("unknown builtin")
      }
    }
  }
}

///|
fn[T] builtin_named_arg_error(builtin : Builtin) -> T raise {
  runtime_error(
    "builtin '\{builtin_name(builtin)}' does not accept named arguments",
  )
}

///|
fn builtin_name(builtin : Builtin) -> String {
  match builtin {
    BRef => "ref"
    BSay => "say"
    BMap => "map"
  }
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
fn eval_param_defaults(params : Array[Param], env : Env) -> Array[Value?] raise {
  params.map(param => eval_param_default_at_definition(param, env))
}

///|
fn eval_param_default_at_definition(param : Param, env : Env) -> Value? raise {
  let Param(_, default_expr, _) = param
  guard default_expr is Some(expr) else { return None }
  Some(eval_with_env(expr, env))
}

///|
fn bind_params(
  params : Array[Param],
  args : Array[EvaluatedCallArg],
  base : Env,
  default_values : Array[Value?],
) -> Env raise {
  let assigned = params.map(_ => None)
  bind_named_args(params, args, assigned)
  bind_positional_args(params, args, assigned, 0, 0)
  let provided_count = count_assigned_values(assigned, 0, 0)
  let required_count = count_required_params(default_values, 0, 0)
  finalize_param_bindings(
    params, assigned, default_values, provided_count, required_count, base, 0,
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
  default_values : Array[Value?],
  provided_count : Int,
  required_count : Int,
  env : Env,
  i : Int,
) -> Env raise {
  guard i < params.length() else { env }
  let Param(pattern, _, _) = params[i]
  let value = match assigned[i] {
    Some(v) => v
    None =>
      match default_values[i] {
        Some(v) => v
        None => arity_error(required_count, provided_count)
      }
  }
  let next_env = bind_pattern(pattern, value, env)
  finalize_param_bindings(
    params,
    assigned,
    default_values,
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
fn count_required_params(
  default_values : Array[Value?],
  i : Int,
  acc : Int,
) -> Int {
  guard i < default_values.length() else { acc }
  match default_values[i] {
    Some(_) => count_required_params(default_values, i + 1, acc)
    None => count_required_params(default_values, i + 1, acc + 1)
  }
}

///|
/// Helpers: expression list evaluation
fn eval_expr_list(exprs : Array[Expr], env : Env) -> Array[Value] raise {
  exprs.map(expr => eval_with_env(expr, env))
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
    guard env.get(name) is Some(func_value) else {
      missing_field_error(name, target_value)
    }
    guard value_is_function(func_value) else {
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
    guard env.get(name) is Some(func_value) else {
      missing_field_error(name, target_value)
    }
    guard value_is_function(func_value) else {
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
fn function_param_count(value : Value) -> Int? {
  match value {
    VClosure(params, _, _, _) => Some(params.length())
    VRecClosure(_, params, _, _, _, _) => Some(params.length())
    VBuiltin(BRef) => Some(1)
    VBuiltin(BSay) => Some(1)
    VBuiltin(BMap) => Some(2)
    _ => None
  }
}

///|
fn apply_ufcs(
  name : String,
  target_value : Value,
  args : Array[EvaluatedCallArg],
  env : Env,
) -> Value raise {
  let func_value = lookup(env, name)
  apply(func_value, [EArgPos(target_value)] + args)
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
      eval_if_pattern_arms_with_fallback(value, arms, None, env)
    }
  }
}

///|
fn eval_if_pattern_arms_with_fallback(
  value : Value,
  arms : Array[IfPatternArm],
  fallback : Expr?,
  env : Env,
) -> Value? raise {
  for arm in arms {
    let IfPatternArm(pattern, arm_guard) = arm
    if try_bind_pattern(pattern, value, env) is Some(bound_env) &&
      eval_if_guard(arm_guard, bound_env) is Some(result) {
      break Some(result)
    }
  } nobreak {
    fallback.map(default_expr => eval_with_env(default_expr, env))
  }
}

///|
fn bind_pattern(pattern : MatchPattern, value : Value, env : Env) -> Env raise {
  guard try_bind_pattern(pattern, value, env) is Some(bound_env) else {
    runtime_error(
      "pattern match failure: expected \{pattern_summary(pattern)}, got \{value_summary(value)}",
    )
  }
  bound_env
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
    POr(patterns) => try_bind_or_pattern(patterns, value, env)
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
  guard i < patterns.length() else { Some(env) }
  guard try_bind_pattern(patterns[i], values[i], env) is Some(next_env) else {
    None
  }
  try_bind_list_pattern(patterns, values, next_env, i + 1)
}

///|
fn try_bind_record_match_pattern(
  patterns : Array[(String, MatchPattern)],
  values : @hashmap.HashMap[String, Value],
  env : Env,
  i : Int,
) -> Env? {
  guard i < patterns.length() else { Some(env) }
  let (field_name, pattern) = patterns[i]
  guard values.get(field_name) is Some(value) else { None }
  guard try_bind_pattern(pattern, value, env) is Some(next_env) else { None }
  try_bind_record_match_pattern(patterns, values, next_env, i + 1)
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
  guard values.length() >= prefix_len + suffix_len else { None }
  guard try_bind_list_pattern(prefix, values, env, 0) is Some(prefix_env) else {
    None
  }
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

///|
fn try_bind_list_suffix_pattern(
  suffix : Array[MatchPattern],
  values : Array[Value],
  env : Env,
  start : Int,
  i : Int,
) -> Env? {
  guard i < suffix.length() else { Some(env) }
  guard try_bind_pattern(suffix[i], values[start + i], env) is Some(next_env) else {
    None
  }
  try_bind_list_suffix_pattern(suffix, values, next_env, start, i + 1)
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
  guard i < end_ else { acc }
  acc.push(values[i])
  slice_values_from(values, i + 1, end_, acc)
}

///|
fn try_bind_or_pattern(
  patterns : Array[MatchPattern],
  value : Value,
  env : Env,
) -> Env? {
  for pattern in patterns {
    if try_bind_pattern(pattern, value, env) is Some(bound_env) {
      break Some(bound_env)
    }
  } nobreak {
    None
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
    PString(value) => "\"\{value}\""
    PNil => "nil"
    POr(patterns) => join_pattern_summaries(patterns)
    PVariant(tag, inner) => "#\{tag}(\{pattern_summary(inner)})"
    PList(items) => "[\{join_pattern_list(items)}]"
    PListRest(prefix, rest_name, suffix) =>
      "[\{join_list_rest_pattern_parts(prefix, rest_name, suffix)}]"
    PRecord(fields) => "{\{join_record_pattern_fields(fields)}}"
  }
}

///|
fn join_pattern_summaries(patterns : Array[MatchPattern]) -> String {
  patterns.map(pattern_summary).join(" | ")
}

///|
fn join_pattern_list(patterns : Array[MatchPattern]) -> String {
  patterns.map(pattern_summary).join("; ")
}

///|
fn join_list_rest_pattern_parts(
  prefix : Array[MatchPattern],
  rest_name : String,
  suffix : Array[MatchPattern],
) -> String {
  let prefix_text = join_pattern_list(prefix)
  let rest_text = if rest_name == "_" { ".." } else { "..\{rest_name}" }
  let suffix_text = join_pattern_list(suffix)
  if prefix.length() == 0 && suffix.length() == 0 {
    rest_text
  } else if prefix.length() == 0 {
    "\{rest_text}; \{suffix_text}"
  } else if suffix.length() == 0 {
    "\{prefix_text}; \{rest_text}"
  } else {
    "\{prefix_text}; \{rest_text}; \{suffix_text}"
  }
}

///|
fn join_record_pattern_fields(fields : Array[(String, MatchPattern)]) -> String {
  fields
  .map(field => {
    let (field_name, field_pattern) = field
    match field_pattern {
      PBind(name) if name == field_name => field_name
      _ => "\{field_name} = \{pattern_summary(field_pattern)}"
    }
  })
  .join("; ")
}

///|
fn value_summary(value : Value) -> String {
  match value {
    VInt(v) => v.to_string()
    VBool(v) => v.to_string()
    VString(v) => "\"\{v}\""
    VNil => "nil"
    VList(items) => "[\{join_value_list(items)}]"
    VRecord(fields) => "record(\{fields.length()} fields)"
    VVariant(tag, payload) => "#\{tag}(\{value_summary(payload)})"
    VRef(_) => "ref"
    VClosure(_) => "function"
    VRecClosure(_) => "function"
    VBuiltin(_) => "function"
  }
}

///|
fn typed_value_summary(value : Value) -> String {
  match value {
    VInt(v) => "Int(\{v})"
    VBool(v) => "Bool(\{v})"
    VString(v) => "String(\"\{v}\")"
    VNil => "Nil"
    VList(items) => "List([\{join_value_list(items)}])"
    VRecord(fields) => "Record(\{fields.length()} fields)"
    VVariant(tag, payload) => "Variant(#\{tag}(\{value_summary(payload)}))"
    VRef(_) => "Ref"
    VClosure(_) => "Function"
    VRecClosure(_) => "Function"
    VBuiltin(_) => "Function"
  }
}

///|
fn join_value_list(values : Array[Value]) -> String {
  values.map(value_summary).join("; ")
}

///|
fn value_list_is_nil_only(items : Array[Value]) -> Bool {
  items.all(value_is_nil_or_nil_only_list)
}

///|
pub fn value_is_nil_or_nil_only_list(value : Value) -> Bool {
  match value {
    VNil => true
    VList(items) => value_list_is_nil_only(items)
    _ => false
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
fn eval_unary(op : UnOp, value : Value) -> Value raise {
  match op {
    Neg =>
      match value {
        VInt(v) => VInt(-v)
        _ => type_error_unary("unary '-'", "Int", value)
      }
    Bang =>
      match value {
        VRef(cell) => cell.val
        _ => VBool(!truthy(value))
      }
    Dollar =>
      match value {
        VString(v) => VString(v)
        _ => VString(value.to_string())
      }
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
          type_error_binary(
            "operator '+'", "(Int, Int) or (String, String)", left, right,
          )
      }
    Sub =>
      match (left, right) {
        (VInt(a), VInt(b)) => VInt(a - b)
        _ => type_error_binary("operator '-'", "(Int, Int)", left, right)
      }
    Mul =>
      match (left, right) {
        (VInt(a), VInt(b)) => VInt(a * b)
        (VInt(times), VString(text)) => VString(text.repeat(times))
        (VString(text), VInt(times)) => VString(text.repeat(times))
        (VInt(times), VList(items)) => VList(repeat_list(items, times))
        (VList(items), VInt(times)) => VList(repeat_list(items, times))
        _ =>
          type_error_binary(
            "operator '*'", "(Int, Int) or (Int, String) or (String, Int) or (Int, List) or (List, Int)",
            left, right,
          )
      }
    Div =>
      match (left, right) {
        (VInt(_), VInt(0)) => VInt(0)
        (VInt(a), VInt(b)) => VInt(a / b)
        _ => type_error_binary("operator '/'", "(Int, Int)", left, right)
      }
    Mod =>
      match (left, right) {
        (VInt(a), VInt(0)) => VInt(a)
        (VInt(a), VInt(b)) => VInt(a % b)
        _ => type_error_binary("operator '%'", "(Int, Int)", left, right)
      }
    Eq => VBool(left == right)
    Ne => VBool(left != right)
    Lt =>
      match (left, right) {
        (VInt(a), VInt(b)) => VBool(a < b)
        _ => type_error_binary("operator '<'", "(Int, Int)", left, right)
      }
    Le =>
      match (left, right) {
        (VInt(a), VInt(b)) => VBool(a <= b)
        _ => type_error_binary("operator '<='", "(Int, Int)", left, right)
      }
    Gt =>
      match (left, right) {
        (VInt(a), VInt(b)) => VBool(a > b)
        _ => type_error_binary("operator '>'", "(Int, Int)", left, right)
      }
    Ge =>
      match (left, right) {
        (VInt(a), VInt(b)) => VBool(a >= b)
        _ => type_error_binary("operator '>='", "(Int, Int)", left, right)
      }
    And => if truthy(left) { right } else { left }
    Or => if truthy(left) { left } else { right }
    RefSet
    | RefUpdateAdd
    | RefUpdateSub
    | RefUpdateMul
    | RefUpdateDiv
    | RefUpdateMod
    | RefUpdateAnd
    | RefUpdateOr => runtime_error("internal: ref binary op in eval_binary")
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
fn ref_update_to_base_binop(op : BinOp) -> BinOp raise {
  match op {
    RefUpdateAdd => Add
    RefUpdateSub => Sub
    RefUpdateMul => Mul
    RefUpdateDiv => Div
    RefUpdateMod => Mod
    _ => runtime_error("invalid numeric ref update operator")
  }
}

///|
fn ref_binary_operator_text(op : BinOp) -> String {
  match op {
    RefSet => "operator ':='"
    RefUpdateAdd => "operator '+='"
    RefUpdateSub => "operator '-='"
    RefUpdateMul => "operator '*='"
    RefUpdateDiv => "operator '/='"
    RefUpdateMod => "operator '%='"
    RefUpdateAnd => "operator '&&='"
    RefUpdateOr => "operator '||='"
    _ => "ref binary operator"
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
    RuntimeErrorAt(message, span) =>
      Some("\{message} at \{format_source_span(span, 0)}")
    _ => None
  } noraise {
    _ => None
  }
}
