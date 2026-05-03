///|
priv enum UnaryBuiltinKind {
  UnaryNeg
  UnaryBang
  UnaryDollar
}

///|
priv enum BinaryBuiltinKind {
  BinaryAdd
  BinarySub
  BinaryMul
  BinaryDiv
  BinaryMod
  BinaryPow
  BinaryEq
  BinaryNe
  BinaryLt
  BinaryLe
  BinaryGt
  BinaryGe
}

///|
priv enum RefUpdateBuiltinKind {
  RefSetBuiltin
  RefUpdateAddBuiltin
  RefUpdateSubBuiltin
  RefUpdateMulBuiltin
  RefUpdateDivBuiltin
  RefUpdateModBuiltin
}

///|
priv enum ShortCircuitBuiltinKind {
  ShortCircuitAnd
  ShortCircuitOr
}

///|
priv enum CollectionBuiltinKind {
  CollectionMap
  CollectionFilter
  CollectionFold
  CollectionLength
  CollectionReverse
  CollectionMax
  CollectionMin
  CollectionSum
}

///|
priv enum EffectBuiltinKind {
  EffectRef
  EffectSay
}

///|
priv enum ConstructorBuiltinKind {
  ConstructorRecord
  ConstructorVariant
}

///|
priv enum BuiltinKind {
  BuiltinUnary(UnaryBuiltinKind)
  BuiltinBinary(BinaryBuiltinKind)
  BuiltinRefUpdate(RefUpdateBuiltinKind)
  BuiltinShortCircuit(ShortCircuitBuiltinKind)
  BuiltinRefShortCircuit(ShortCircuitBuiltinKind)
  BuiltinCollection(CollectionBuiltinKind)
  BuiltinEffect(EffectBuiltinKind)
  BuiltinConstructor(ConstructorBuiltinKind)
}

///|
fn builtin_entries() -> Array[(Builtin, String, BuiltinKind)] {
  [
    (BRef, "ref", BuiltinEffect(EffectRef)),
    (BSay, "say", BuiltinEffect(EffectSay)),
    (BMap, "map", BuiltinCollection(CollectionMap)),
    (BFilter, "filter", BuiltinCollection(CollectionFilter)),
    (BFold, "fold", BuiltinCollection(CollectionFold)),
    (BLength, "length", BuiltinCollection(CollectionLength)),
    (BReverse, "reverse", BuiltinCollection(CollectionReverse)),
    (BMax, "max", BuiltinCollection(CollectionMax)),
    (BMin, "min", BuiltinCollection(CollectionMin)),
    (BSum, "sum", BuiltinCollection(CollectionSum)),
    (BOpAdd, "__operator_add", BuiltinBinary(BinaryAdd)),
    (BOpSub, "__operator_sub", BuiltinBinary(BinarySub)),
    (BOpMul, "__operator_mul", BuiltinBinary(BinaryMul)),
    (BOpDiv, "__operator_div", BuiltinBinary(BinaryDiv)),
    (BOpMod, "__operator_mod", BuiltinBinary(BinaryMod)),
    (BOpPow, "__operator_pow", BuiltinBinary(BinaryPow)),
    (BOpEq, "__operator_eq", BuiltinBinary(BinaryEq)),
    (BOpNe, "__operator_ne", BuiltinBinary(BinaryNe)),
    (BOpLt, "__operator_lt", BuiltinBinary(BinaryLt)),
    (BOpLe, "__operator_le", BuiltinBinary(BinaryLe)),
    (BOpGt, "__operator_gt", BuiltinBinary(BinaryGt)),
    (BOpGe, "__operator_ge", BuiltinBinary(BinaryGe)),
    (BOpNeg, "__operator_neg", BuiltinUnary(UnaryNeg)),
    (BOpBang, "__operator_bang", BuiltinUnary(UnaryBang)),
    (BOpDollar, "__operator_dollar", BuiltinUnary(UnaryDollar)),
    (BOpRefSet, "__operator_ref_set", BuiltinRefUpdate(RefSetBuiltin)),
    (
      BOpRefUpdateAdd,
      "__operator_ref_update_add",
      BuiltinRefUpdate(RefUpdateAddBuiltin),
    ),
    (
      BOpRefUpdateSub,
      "__operator_ref_update_sub",
      BuiltinRefUpdate(RefUpdateSubBuiltin),
    ),
    (
      BOpRefUpdateMul,
      "__operator_ref_update_mul",
      BuiltinRefUpdate(RefUpdateMulBuiltin),
    ),
    (
      BOpRefUpdateDiv,
      "__operator_ref_update_div",
      BuiltinRefUpdate(RefUpdateDivBuiltin),
    ),
    (
      BOpRefUpdateMod,
      "__operator_ref_update_mod",
      BuiltinRefUpdate(RefUpdateModBuiltin),
    ),
    (BOpAnd, "__operator_and", BuiltinShortCircuit(ShortCircuitAnd)),
    (BOpOr, "__operator_or", BuiltinShortCircuit(ShortCircuitOr)),
    (
      BOpRefUpdateAnd,
      "__operator_ref_update_and",
      BuiltinRefShortCircuit(ShortCircuitAnd),
    ),
    (
      BOpRefUpdateOr,
      "__operator_ref_update_or",
      BuiltinRefShortCircuit(ShortCircuitOr),
    ),
    (BRecord, "__record", BuiltinConstructor(ConstructorRecord)),
    (BVariant, "__variant", BuiltinConstructor(ConstructorVariant)),
  ]
}

///|
fn find_builtin_entry(builtin : Builtin) -> (Builtin, String, BuiltinKind) {
  find_builtin_entry_from(builtin_entries(), builtin, 0)
}

///|
fn find_builtin_entry_from(
  entries : Array[(Builtin, String, BuiltinKind)],
  builtin : Builtin,
  i : Int,
) -> (Builtin, String, BuiltinKind) {
  guard i < entries.length() else { abort("unknown builtin") }
  let entry = entries[i]
  let (candidate, _, _) = entry
  if candidate == builtin {
    entry
  } else {
    find_builtin_entry_from(entries, builtin, i + 1)
  }
}

///|
fn apply_builtin(
  builtin : Builtin,
  args : Array[EvaluatedCallArg],
) -> Value raise {
  let (_, name, kind) = find_builtin_entry(builtin)
  match kind {
    BuiltinUnary(op) => apply_builtin_unary(op, builtin, args)
    BuiltinBinary(op) => apply_builtin_binary(op, builtin, args)
    BuiltinRefUpdate(op) => apply_builtin_ref_update(op, builtin, args)
    BuiltinShortCircuit(op) => apply_builtin_short_circuit(op, builtin, args)
    BuiltinRefShortCircuit(op) =>
      apply_builtin_ref_short_circuit(op, builtin, args)
    BuiltinCollection(op) => apply_builtin_collection(op, name, builtin, args)
    BuiltinEffect(op) => apply_builtin_effect(op, builtin, args)
    BuiltinConstructor(op) => apply_builtin_constructor(op, args)
  }
}

///|
fn[T] builtin_named_arg_error(builtin : Builtin) -> T raise {
  runtime_error(
    "builtin '\{builtin_name(builtin)}' does not accept named arguments",
  )
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
fn builtin_name(builtin : Builtin) -> String {
  let (_, name, _) = find_builtin_entry(builtin)
  name
}

///|
fn apply_builtin_unary(
  op : UnaryBuiltinKind,
  builtin : Builtin,
  args : Array[EvaluatedCallArg],
) -> Value raise {
  match op {
    UnaryNeg =>
      apply_unary_operator_builtin(builtin, args, fn(value) raise {
        match value {
          VInt(v) => VInt(-v)
          _ => type_error_unary("unary '~'", "Int", value)
        }
      })
    UnaryBang =>
      apply_unary_operator_builtin(builtin, args, fn(value) {
        match value {
          VRef(value~) => value
          _ => VBool(!truthy(value))
        }
      })
    UnaryDollar =>
      apply_unary_operator_builtin(builtin, args, fn(value) {
        VString(value.to_string())
      })
  }
}

///|
fn apply_builtin_binary(
  op : BinaryBuiltinKind,
  builtin : Builtin,
  args : Array[EvaluatedCallArg],
) -> Value raise {
  match op {
    BinaryAdd =>
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
    BinarySub =>
      apply_binary_operator_builtin(builtin, args, fn(left, right) raise {
        match (left, right) {
          (VInt(a), VInt(b)) => VInt(a - b)
          _ => type_error_binary("operator '-'", "(Int, Int)", left, right)
        }
      })
    BinaryMul =>
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
    BinaryDiv =>
      apply_binary_operator_builtin(builtin, args, fn(left, right) raise {
        match (left, right) {
          (VInt(_), VInt(0)) => VInt(0)
          (VInt(a), VInt(b)) => VInt(a / b)
          _ => type_error_binary("operator '/'", "(Int, Int)", left, right)
        }
      })
    BinaryMod =>
      apply_binary_operator_builtin(builtin, args, fn(left, right) raise {
        match (left, right) {
          (VInt(a), VInt(0)) => VInt(a)
          (VInt(a), VInt(b)) => VInt(a % b)
          _ => type_error_binary("operator '%'", "(Int, Int)", left, right)
        }
      })
    BinaryPow =>
      apply_binary_operator_builtin(builtin, args, fn(left, right) raise {
        match (left, right) {
          (VInt(a), VInt(b)) => VInt(int_pow(a, b))
          _ => type_error_binary("operator '^'", "(Int, Int)", left, right)
        }
      })
    BinaryEq =>
      apply_binary_operator_builtin(builtin, args, fn(left, right) {
        VBool(left == right)
      })
    BinaryNe =>
      apply_binary_operator_builtin(builtin, args, fn(left, right) {
        VBool(left != right)
      })
    BinaryLt =>
      apply_int_compare_operator_builtin(builtin, args, "operator '<'", fn(
        a,
        b,
      ) {
        a < b
      })
    BinaryLe =>
      apply_int_compare_operator_builtin(builtin, args, "operator '<='", fn(
        a,
        b,
      ) {
        a <= b
      })
    BinaryGt =>
      apply_int_compare_operator_builtin(builtin, args, "operator '>'", fn(
        a,
        b,
      ) {
        a > b
      })
    BinaryGe =>
      apply_int_compare_operator_builtin(builtin, args, "operator '>='", fn(
        a,
        b,
      ) {
        a >= b
      })
  }
}

///|
fn apply_builtin_ref_update(
  op : RefUpdateBuiltinKind,
  builtin : Builtin,
  args : Array[EvaluatedCallArg],
) -> Value raise {
  match op {
    RefSetBuiltin =>
      apply_ref_operator_builtin(builtin, args, "operator ':='", fn(_, right) {
        right
      })
    RefUpdateAddBuiltin =>
      apply_ref_operator_builtin(builtin, args, "operator '+='", fn(
        left,
        right,
      ) raise {
        apply_builtin(BOpAdd, [EArgPos(left), EArgPos(right)])
      })
    RefUpdateSubBuiltin =>
      apply_ref_operator_builtin(builtin, args, "operator '-='", fn(
        left,
        right,
      ) raise {
        apply_builtin(BOpSub, [EArgPos(left), EArgPos(right)])
      })
    RefUpdateMulBuiltin =>
      apply_ref_operator_builtin(builtin, args, "operator '*='", fn(
        left,
        right,
      ) raise {
        apply_builtin(BOpMul, [EArgPos(left), EArgPos(right)])
      })
    RefUpdateDivBuiltin =>
      apply_ref_operator_builtin(builtin, args, "operator '/='", fn(
        left,
        right,
      ) raise {
        apply_builtin(BOpDiv, [EArgPos(left), EArgPos(right)])
      })
    RefUpdateModBuiltin =>
      apply_ref_operator_builtin(builtin, args, "operator '%='", fn(
        left,
        right,
      ) raise {
        apply_builtin(BOpMod, [EArgPos(left), EArgPos(right)])
      })
  }
}

///|
fn apply_builtin_short_circuit(
  op : ShortCircuitBuiltinKind,
  builtin : Builtin,
  args : Array[EvaluatedCallArg],
) -> Value raise {
  match op {
    ShortCircuitAnd =>
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
    ShortCircuitOr =>
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
  }
}

///|
fn apply_builtin_ref_short_circuit(
  op : ShortCircuitBuiltinKind,
  builtin : Builtin,
  args : Array[EvaluatedCallArg],
) -> Value raise {
  match op {
    ShortCircuitAnd =>
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
    ShortCircuitOr =>
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
  }
}

///|
fn apply_builtin_collection(
  op : CollectionBuiltinKind,
  name : String,
  builtin : Builtin,
  args : Array[EvaluatedCallArg],
) -> Value raise {
  match op {
    CollectionMap => {
      guard args.length() == 2 else { arity_error(2, args.length()) }
      guard args is [EArgPos(list_value), EArgPos(func_value)] else {
        builtin_named_arg_error(builtin)
      }
      guard list_value is VList(items) else {
        builtin_type_error(name, "List", list_value)
      }
      guard value_is_function(func_value) else {
        builtin_type_error(name, "Function", func_value)
      }
      VList(items.map(item => apply(func_value, [EArgPos(item)])))
    }
    CollectionFilter => {
      guard args.length() == 2 else { arity_error(2, args.length()) }
      guard args is [EArgPos(list_value), EArgPos(func_value)] else {
        builtin_named_arg_error(builtin)
      }
      guard list_value is VList(items) else {
        builtin_type_error(name, "List", list_value)
      }
      guard value_is_function(func_value) else {
        builtin_type_error(name, "Function", func_value)
      }
      VList(filter_builtin_items(items, func_value))
    }
    CollectionFold => {
      guard args.length() == 3 else { arity_error(3, args.length()) }
      guard args
        is [EArgPos(list_value), EArgPos(init_value), EArgPos(func_value)] else {
        builtin_named_arg_error(builtin)
      }
      guard list_value is VList(items) else {
        builtin_type_error(name, "List", list_value)
      }
      guard value_is_function(func_value) else {
        builtin_type_error(name, "Function", func_value)
      }
      fold_builtin_items(items, init_value, func_value)
    }
    CollectionLength => {
      guard args.length() == 1 else { arity_error(1, args.length()) }
      guard args is [EArgPos(v)] else { builtin_named_arg_error(builtin) }
      match v {
        VString(text) => VInt(text.length())
        VList(items) => VInt(items.length())
        _ => builtin_type_error(name, "String or List", v)
      }
    }
    CollectionReverse => {
      guard args.length() == 1 else { arity_error(1, args.length()) }
      guard args is [EArgPos(v)] else { builtin_named_arg_error(builtin) }
      match v {
        VString(text) => VString(text.rev())
        VList(items) => VList(items.rev())
        _ => builtin_type_error(name, "String or List", v)
      }
    }
    CollectionMax => apply_builtin_max_or_min(true, args)
    CollectionMin => apply_builtin_max_or_min(false, args)
    CollectionSum => apply_builtin_sum(args)
  }
}

///|
fn apply_builtin_effect(
  op : EffectBuiltinKind,
  builtin : Builtin,
  args : Array[EvaluatedCallArg],
) -> Value raise {
  guard args.length() == 1 else { arity_error(1, args.length()) }
  guard args is [EArgPos(v)] else { builtin_named_arg_error(builtin) }
  match op {
    EffectRef => VRef(value=v)
    EffectSay => {
      match v {
        VString(text) => println(text)
        _ => println(v)
      }
      VNil
    }
  }
}

///|
fn apply_builtin_constructor(
  op : ConstructorBuiltinKind,
  args : Array[EvaluatedCallArg],
) -> Value raise {
  match op {
    ConstructorRecord => apply_builtin_record(args)
    ConstructorVariant => apply_builtin_variant(args)
  }
}

///|
fn apply_builtin_record(args : Array[EvaluatedCallArg]) -> Value raise {
  VRecord <| args.fold(init=@hashmap.new(), (fields, arg) => {
    guard arg is EArgNamed(name, value) else {
      runtime_error("builtin '__record' only accepts named arguments")
    }
    fields.add(name, value)
  })
}

///|
fn apply_builtin_variant(args : Array[EvaluatedCallArg]) -> Value raise {
  guard args.length() == 2 else { arity_error(2, args.length()) }
  match args {
    [EArgPos(VString(tag)), EArgPos(payload)] => VVariant(tag, payload)
    [EArgPos(tag_value), EArgPos(_)] =>
      builtin_type_error("__variant", "String tag", tag_value)
    _ => builtin_named_arg_error(BVariant)
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
