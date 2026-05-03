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
    StaticErrorAt(message, span) =>
      Some("\{message} at \{format_source_span(span, 0)}")
    RuntimeErrorAt(message, span) =>
      Some("\{message} at \{format_source_span(span, 0)}")
    _ => None
  } noraise {
    _ => None
  }
}
