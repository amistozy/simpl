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
    VClosure(params, body, closure_env) => {
      let call_env = bind_params(params, args, closure_env)
      eval_with_env(body, call_env)
    }
    VRecClosure(_, params, body, closure_env, defs) => {
      let call_base_env = build_rec_env(defs, closure_env)
      let call_env = bind_params(params, args, call_base_env)
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
  guard args is [EArgPos(arg)] else {
    runtime_error("list call only accepts positional arguments")
  }
  if value_is_function(arg) {
    let acc = []
    for item in items {
      append_result(acc, apply(arg, [EArgPos(item)]))
    }
    return VList(acc)
  }
  match arg {
    VInt(index) => list_get_by_index(items, index)
    VString(separator) => VString(join_values_with_separator(items, separator))
    VList(index_values) => {
      let acc = []
      for index_value in index_values {
        match index_value {
          VInt(index) => acc.push(list_get_by_index(items, index))
          _ =>
            runtime_error(
              "list call expected Int, String, List[Int], or Function, got \{typed_value_summary(arg)}",
            )
        }
      }
      VList(acc)
    }
    _ =>
      runtime_error(
        "list call expected Int, String, List[Int], or Function, got \{typed_value_summary(arg)}",
      )
  }
}

///|
fn list_get_by_index(items : Array[Value], index : Int) -> Value {
  let len = items.length()
  let normalized = if index < 0 { len + index } else { index }
  if normalized < 0 || normalized >= len {
    VNil
  } else {
    items[normalized]
  }
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
      if times <= 0 {
        VList([])
      } else {
        VList(repeat_function_results(value, times))
      }
    }
  }
}

///|
fn repeat_function_results(
  func_value : Value,
  times : Int,
) -> Array[Value] raise {
  let acc = []
  for _ in 0..<times {
    append_result(acc, apply(func_value, []))
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
    BOpNeg =>
      apply_unary_operator_builtin(builtin, args, fn(value) raise {
        match value {
          VInt(v) => VInt(-v)
          _ => type_error_unary("unary '~'", "Int", value)
        }
      })
    BOpBang =>
      apply_unary_operator_builtin(builtin, args, fn(value) {
        match value {
          VRef(value~) => value
          _ => VBool(!truthy(value))
        }
      })
    BOpDollar =>
      apply_unary_operator_builtin(builtin, args, fn(value) {
        VString(value.to_string())
      })
    BOpAdd =>
      apply_binary_operator_builtin(builtin, args, fn(left, right) raise {
        match (left, right) {
          (VInt(a), VInt(b)) => VInt(a + b)
          (VString(a), VString(b)) => VString(a + b)
          (VList(a), VList(b)) => VList(a + b)
          _ =>
            type_error_binary(
              "operator '+'", "(Int, Int) or (String, String) or (List, List)", left,
              right,
            )
        }
      })
    BOpSub =>
      apply_binary_operator_builtin(builtin, args, fn(left, right) raise {
        match (left, right) {
          (VInt(a), VInt(b)) => VInt(a - b)
          _ => type_error_binary("operator '-'", "(Int, Int)", left, right)
        }
      })
    BOpMul =>
      apply_binary_operator_builtin(builtin, args, fn(left, right) raise {
        match (left, right) {
          (VInt(a), VInt(b)) => VInt(a * b)
          (VInt(times), VString(text)) | (VString(text), VInt(times)) =>
            VString(text.repeat(times))
          (VInt(times), VList(items)) | (VList(items), VInt(times)) =>
            VList(repeat_list(items, times))
          (VInt(times), func_value) | (func_value, VInt(times)) if value_is_function(
              func_value,
            ) => VList(repeat_function_results(func_value, times))
          _ =>
            type_error_binary(
              "operator '*'", "(Int, Int) or (Int, String) or (String, Int) or (Int, List) or (List, Int) or (Int, Function) or (Function, Int)",
              left, right,
            )
        }
      })
    BOpDiv =>
      apply_binary_operator_builtin(builtin, args, fn(left, right) raise {
        match (left, right) {
          (VInt(_), VInt(0)) => VInt(0)
          (VInt(a), VInt(b)) => VInt(a / b)
          _ => type_error_binary("operator '/'", "(Int, Int)", left, right)
        }
      })
    BOpMod =>
      apply_binary_operator_builtin(builtin, args, fn(left, right) raise {
        match (left, right) {
          (VInt(a), VInt(0)) => VInt(a)
          (VInt(a), VInt(b)) => VInt(a % b)
          _ => type_error_binary("operator '%'", "(Int, Int)", left, right)
        }
      })
    BOpPow =>
      apply_binary_operator_builtin(builtin, args, fn(left, right) raise {
        match (left, right) {
          (VInt(a), VInt(b)) => VInt(int_pow(a, b))
          _ => type_error_binary("operator '^'", "(Int, Int)", left, right)
        }
      })
    BOpEq =>
      apply_binary_operator_builtin(builtin, args, fn(left, right) {
        VBool(left == right)
      })
    BOpNe =>
      apply_binary_operator_builtin(builtin, args, fn(left, right) {
        VBool(left != right)
      })
    BOpLt =>
      apply_int_compare_operator_builtin(builtin, args, "operator '<'", fn(
        a,
        b,
      ) {
        a < b
      })
    BOpLe =>
      apply_int_compare_operator_builtin(builtin, args, "operator '<='", fn(
        a,
        b,
      ) {
        a <= b
      })
    BOpGt =>
      apply_int_compare_operator_builtin(builtin, args, "operator '>'", fn(
        a,
        b,
      ) {
        a > b
      })
    BOpGe =>
      apply_int_compare_operator_builtin(builtin, args, "operator '>='", fn(
        a,
        b,
      ) {
        a >= b
      })
    BOpRefSet =>
      apply_ref_operator_builtin(builtin, args, "operator ':='", fn(_, right) {
        right
      })
    BOpRefUpdateAdd =>
      apply_ref_operator_builtin(builtin, args, "operator '+='", fn(
        left,
        right,
      ) raise {
        apply_builtin(BOpAdd, [EArgPos(left), EArgPos(right)])
      })
    BOpRefUpdateSub =>
      apply_ref_operator_builtin(builtin, args, "operator '-='", fn(
        left,
        right,
      ) raise {
        apply_builtin(BOpSub, [EArgPos(left), EArgPos(right)])
      })
    BOpRefUpdateMul =>
      apply_ref_operator_builtin(builtin, args, "operator '*='", fn(
        left,
        right,
      ) raise {
        apply_builtin(BOpMul, [EArgPos(left), EArgPos(right)])
      })
    BOpRefUpdateDiv =>
      apply_ref_operator_builtin(builtin, args, "operator '/='", fn(
        left,
        right,
      ) raise {
        apply_builtin(BOpDiv, [EArgPos(left), EArgPos(right)])
      })
    BOpRefUpdateMod =>
      apply_ref_operator_builtin(builtin, args, "operator '%='", fn(
        left,
        right,
      ) raise {
        apply_builtin(BOpMod, [EArgPos(left), EArgPos(right)])
      })
    BOpAnd =>
      apply_short_circuit_operator_builtin(builtin, args, fn(
        left,
        thunk,
      ) raise {
        if truthy(left) {
          apply(thunk, [])
        } else {
          left
        }
      })
    BOpOr =>
      apply_short_circuit_operator_builtin(builtin, args, fn(
        left,
        thunk,
      ) raise {
        if truthy(left) {
          left
        } else {
          apply(thunk, [])
        }
      })
    BOpRefUpdateAnd =>
      apply_ref_short_circuit_operator_builtin(
        builtin,
        args,
        "operator '&&='",
        fn(old_value, thunk) raise {
          if truthy(old_value) {
            apply(thunk, [])
          } else {
            old_value
          }
        },
      )
    BOpRefUpdateOr =>
      apply_ref_short_circuit_operator_builtin(
        builtin,
        args,
        "operator '||='",
        fn(old_value, thunk) raise {
          if truthy(old_value) {
            old_value
          } else {
            apply(thunk, [])
          }
        },
      )
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
    BFilter => {
      guard args.length() == 2 else { arity_error(2, args.length()) }
      guard args is [EArgPos(list_value), EArgPos(func_value)] else {
        builtin_named_arg_error(builtin)
      }
      guard list_value is VList(items) else {
        builtin_type_error("filter", "List", list_value)
      }
      guard value_is_function(func_value) else {
        builtin_type_error("filter", "Function", func_value)
      }
      VList(filter_builtin_items(items, func_value))
    }
    BFold => {
      guard args.length() == 3 else { arity_error(3, args.length()) }
      guard args
        is [EArgPos(list_value), EArgPos(init_value), EArgPos(func_value)] else {
        builtin_named_arg_error(builtin)
      }
      guard list_value is VList(items) else {
        builtin_type_error("fold", "List", list_value)
      }
      guard value_is_function(func_value) else {
        builtin_type_error("fold", "Function", func_value)
      }
      fold_builtin_items(items, init_value, func_value)
    }
    BLength => {
      guard args.length() == 1 else { arity_error(1, args.length()) }
      guard args is [EArgPos(v)] else { builtin_named_arg_error(builtin) }
      match v {
        VString(text) => VInt(text.length())
        VList(items) => VInt(items.length())
        _ => builtin_type_error("length", "String or List", v)
      }
    }
    BReverse => {
      guard args.length() == 1 else { arity_error(1, args.length()) }
      guard args is [EArgPos(v)] else { builtin_named_arg_error(builtin) }
      match v {
        VString(text) => VString(text.rev())
        VList(items) => VList(items.rev())
        _ => builtin_type_error("reverse", "String or List", v)
      }
    }
    BMax => apply_builtin_max_or_min(true, args)
    BMin => apply_builtin_max_or_min(false, args)
    BSum => apply_builtin_sum(args)
    _ => {
      guard args.length() == 1 else { arity_error(1, args.length()) }
      guard args is [EArgPos(v)] else { builtin_named_arg_error(builtin) }
      match builtin {
        BRef => VRef(value=v)
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
    BFilter => "filter"
    BFold => "fold"
    BLength => "length"
    BReverse => "reverse"
    BMax => "max"
    BMin => "min"
    BSum => "sum"
    BOpAdd => "__operator_add"
    BOpSub => "__operator_sub"
    BOpMul => "__operator_mul"
    BOpDiv => "__operator_div"
    BOpMod => "__operator_mod"
    BOpPow => "__operator_pow"
    BOpEq => "__operator_eq"
    BOpNe => "__operator_ne"
    BOpLt => "__operator_lt"
    BOpLe => "__operator_le"
    BOpGt => "__operator_gt"
    BOpGe => "__operator_ge"
    BOpNeg => "__operator_neg"
    BOpBang => "__operator_bang"
    BOpDollar => "__operator_dollar"
    BOpRefSet => "__operator_ref_set"
    BOpRefUpdateAdd => "__operator_ref_update_add"
    BOpRefUpdateSub => "__operator_ref_update_sub"
    BOpRefUpdateMul => "__operator_ref_update_mul"
    BOpRefUpdateDiv => "__operator_ref_update_div"
    BOpRefUpdateMod => "__operator_ref_update_mod"
    BOpAnd => "__operator_and"
    BOpOr => "__operator_or"
    BOpRefUpdateAnd => "__operator_ref_update_and"
    BOpRefUpdateOr => "__operator_ref_update_or"
  }
}

///|
fn apply_unary_operator_builtin(
  builtin : Builtin,
  args : Array[EvaluatedCallArg],
  func : (Value) -> Value raise,
) -> Value raise {
  guard args.length() == 1 else { arity_error(1, args.length()) }
  guard args is [EArgPos(value)] else { builtin_named_arg_error(builtin) }
  func(value)
}

///|
fn apply_binary_operator_builtin(
  builtin : Builtin,
  args : Array[EvaluatedCallArg],
  func : (Value, Value) -> Value raise,
) -> Value raise {
  guard args.length() == 2 else { arity_error(2, args.length()) }
  guard args is [EArgPos(left), EArgPos(right)] else {
    builtin_named_arg_error(builtin)
  }
  func(left, right)
}

///|
fn apply_ref_operator_builtin(
  builtin : Builtin,
  args : Array[EvaluatedCallArg],
  operator : String,
  func : (Value, Value) -> Value raise,
) -> Value raise {
  apply_binary_operator_builtin(builtin, args, fn(left, right) raise {
    match left {
      VRef(_) as cell => {
        let new_value = func(cell.value, right)
        cell.value = new_value
        new_value
      }
      value => type_error_unary(operator, "Ref on left side", value)
    }
  })
}

///|
fn apply_short_circuit_operator_builtin(
  builtin : Builtin,
  args : Array[EvaluatedCallArg],
  func : (Value, Value) -> Value raise,
) -> Value raise {
  guard args.length() == 2 else { arity_error(2, args.length()) }
  guard args is [EArgPos(left), EArgPos(thunk)] else {
    builtin_named_arg_error(builtin)
  }
  guard value_is_function(thunk) else {
    builtin_type_error(builtin_name(builtin), "Function", thunk)
  }
  func(left, thunk)
}

///|
fn apply_ref_short_circuit_operator_builtin(
  builtin : Builtin,
  args : Array[EvaluatedCallArg],
  operator : String,
  func : (Value, Value) -> Value raise,
) -> Value raise {
  apply_short_circuit_operator_builtin(builtin, args, fn(left, thunk) raise {
    match left {
      VRef(_) as cell => {
        let new_value = func(cell.value, thunk)
        cell.value = new_value
        new_value
      }
      value => type_error_unary(operator, "Ref on left side", value)
    }
  })
}

///|
fn apply_int_compare_operator_builtin(
  builtin : Builtin,
  args : Array[EvaluatedCallArg],
  operator : String,
  func : (Int, Int) -> Bool,
) -> Value raise {
  apply_binary_operator_builtin(builtin, args, fn(left, right) raise {
    match (left, right) {
      (VInt(a), VInt(b)) => VBool(func(a, b))
      _ => type_error_binary(operator, "(Int, Int)", left, right)
    }
  })
}

///|
fn filter_builtin_items(
  items : Array[Value],
  func_value : Value,
) -> Array[Value] raise {
  items.filter(item => truthy(apply(func_value, [EArgPos(item)])))
}

///|
fn fold_builtin_items(
  items : Array[Value],
  init_value : Value,
  func_value : Value,
) -> Value raise {
  items.fold(init=init_value, (acc, item) => {
    apply(func_value, [EArgPos(acc), EArgPos(item)])
  })
}

///|
fn apply_builtin_sum(args : Array[EvaluatedCallArg]) -> Value raise {
  match args {
    [EArgPos(VList(items))] =>
      VInt(
        items
        .map(item => value_as_int_for_builtin("sum", item))
        .fold(init=0, Int::add),
      )
    [EArgPos(v)] => builtin_type_error("sum", "List", v)
    [_] => runtime_error("builtin 'sum' does not accept named arguments")
    _ => arity_error(1, args.length())
  }
}

///|
fn apply_builtin_max_or_min(
  is_max : Bool,
  args : Array[EvaluatedCallArg],
) -> Value raise {
  let name = if is_max { "max" } else { "min" }
  match args {
    [EArgPos(a), EArgPos(b)] =>
      VInt(
        select_max_or_min_ints(
          is_max,
          value_as_int_for_builtin(name, a),
          value_as_int_for_builtin(name, b),
        ),
      )
    [EArgPos(VList(items))] =>
      VInt(
        reduce_max_or_min_int_list(
          is_max,
          items.map(item => value_as_int_for_builtin(name, item)),
          name,
        ),
      )
    [EArgPos(v)] => builtin_type_error(name, "List or (Int, Int)", v)
    _ if args.length() == 1 || args.length() == 2 =>
      runtime_error("builtin '\{name}' does not accept named arguments")
    _ =>
      runtime_error(
        "arity error: expected 1 or 2 arguments, got \{args.length()}",
      )
  }
}

///|
fn value_as_int_for_builtin(name : String, value : Value) -> Int raise {
  match value {
    VInt(v) => v
    _ => builtin_type_error(name, "Int", value)
  }
}

///|
fn select_max_or_min_ints(is_max : Bool, a : Int, b : Int) -> Int {
  if is_max {
    a.max(b)
  } else {
    a.min(b)
  }
}

///|
fn reduce_max_or_min_int_list(
  is_max : Bool,
  items : Array[Int],
  name : String,
) -> Int raise {
  guard items is [head, .. tail] else {
    runtime_error("builtin '\{name}' expected non-empty List")
  }
  tail.fold(init=head, (acc, item) => select_max_or_min_ints(is_max, acc, item))
}
