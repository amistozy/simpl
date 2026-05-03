///|
fn compile(source : String) -> Expr raise {
  let expr = desugar(parse(source))
  validate(expr)
  expr
}

///|
pub fn eval_source(source : String) -> Value raise {
  eval(compile(source))
}

///|
pub fn eval_source_is_int(source : String, expected : Int) -> Bool {
  try eval_source(source) catch {
    _ => false
  } noraise {
    VInt(v) => v == expected
    _ => false
  }
}

///|
pub fn eval_source_is_error(source : String) -> Bool {
  try eval_source(source) catch {
    _ => true
  } noraise {
    _ => false
  }
}

///|
pub fn format_error(error : Error, line_offset : Int) -> String {
  match error {
    SyntaxErrorAt(message, span)
    | RuntimeErrorAt(message, span)
    | StaticErrorAt(message, span) =>
      "\{message} at \{format_source_span(span, line_offset)}"
    _ => error.to_string()
  }
}
