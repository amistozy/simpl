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
    PAs(inner, name) => {
      guard try_bind_pattern(inner, value, env) is Some(next_env) else { None }
      if name == "_" {
        Some(next_env)
      } else {
        Some(next_env.add(name, value))
      }
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
    PAs(inner, name) => "\{pattern_summary(inner)} as \{name}"
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
