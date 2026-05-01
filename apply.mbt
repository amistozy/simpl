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
    BLength => {
      guard args.length() == 1 else { arity_error(1, args.length()) }
      guard args is [EArgPos(v)] else { builtin_named_arg_error(builtin) }
      match v {
        VString(text) => VInt(text.length())
        VList(items) => VInt(items.length())
        _ => builtin_type_error("length", "String or List", v)
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
    BLength => "length"
    BMax => "max"
    BMin => "min"
    BSum => "sum"
  }
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
