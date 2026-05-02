///|
fn surface_expr_pretty(expr : SurfaceExpr) -> String {
  match expr {
    SLocated(_, inner) => surface_expr_pretty(inner)
    SIntLit(v) => v.to_string()
    SBoolLit(v) => v.to_string()
    SStringLit(v) => "\"\{v}\""
    SNilLit => "nil"
    SUnderscore => "_"
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
    SGuard(arm, fallback, body) =>
      "guard \{surface_guard_cond_arm_pretty(arm)}\{surface_guard_else_pretty(fallback)}; \{surface_expr_pretty(body)}"
    SLetFun(name, params, func_body, body) =>
      "let \{name}(\{surface_param_list_pretty(params)}) = \{surface_expr_pretty(func_body)}; \{surface_expr_pretty(body)}"
    SLetRec(name, params, func_body, body) =>
      "let rec \{name}(\{surface_param_list_pretty(params)}) = \{surface_expr_pretty(func_body)}; \{surface_expr_pretty(body)}"
    SLetRecAnd(defs, body) =>
      "let rec \{surface_let_rec_defs_pretty(defs)}; \{surface_expr_pretty(body)}"
    SWith(params, target_expr, body) =>
      "with(\{surface_param_list_pretty(params)}) = \{surface_expr_pretty(target_expr)}; \{surface_expr_pretty(body)}"
    SLambda(params, body) =>
      "fn(\{surface_param_list_pretty(params)}) \{surface_expr_pretty(body)}"
    SFnEta(body) => "fn \{surface_expr_pretty(body)}"
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
    STrailingArgPos(expr) => surface_expr_pretty(expr)
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
fn surface_guard_else_pretty(fallback : SurfaceExpr?) -> String {
  match fallback {
    Some(expr) => " else \{surface_expr_pretty(expr)}"
    None => ""
  }
}

///|
fn surface_guard_cond_arm_pretty(arm : SurfaceGuardCondArm) -> String {
  match arm {
    SGuardCondArm(cond, tail) =>
      "\{surface_expr_pretty(cond)}\{surface_guard_guard_pretty(tail)}"
  }
}

///|
fn surface_guard_pattern_arm_pretty(arm : SurfaceGuardPatternArm) -> String {
  match arm {
    SGuardPatternArm(pattern, tail) =>
      "\{surface_pattern_pretty(pattern)}\{surface_guard_guard_pretty(tail)}"
  }
}

///|
fn surface_guard_guard_pretty(tail : SurfaceGuardGuard) -> String {
  match tail {
    SGuardPass => ""
    SGuardAnd(arm) => " and \{surface_guard_cond_arm_pretty(arm)}"
    SGuardIs(value_expr, arm) =>
      " is \{surface_expr_pretty(value_expr)} \{surface_guard_pattern_arm_pretty(arm)}"
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
    SPAs(inner, name) => "\{surface_pattern_pretty(inner)} as \{name}"
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
    Pow => "^"
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
    Neg => "~"
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
    VRef(_) as cell => "ref(\{value_pretty(cell.value, depth - 1)})"
    VClosure(_) => "<fn>"
    VRecClosure(name, _, _, _, _) => "<rec \{name}>"
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
