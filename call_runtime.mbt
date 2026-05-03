///|
priv enum EvaluatedCallArg {
  EArgPos(Value)
  EArgNamed(String, Value)
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
fn value_is_function(value : Value) -> Bool {
  match value {
    VClosure(_) => true
    VRecClosure(_) => true
    VBuiltin(_) => true
    _ => false
  }
}

///|
fn apply_record_with_named_args(
  fields : @hashmap.HashMap[String, Value],
  args : Array[EvaluatedCallArg],
) -> Value raise {
  VRecord <| args.fold(init=fields, (fields, arg) => {
    guard arg is EArgNamed(name, value) else {
      runtime_error("record call only accepts named arguments")
    }
    fields.add(name, value)
  })
}

///|
fn repeat_list(items : Array[Value], times : Int) -> Array[Value] {
  if times <= 0 {
    []
  } else {
    items.repeat(times)
  }
}
