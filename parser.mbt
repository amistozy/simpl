///|
type SourcePos = (Int, Int, Int)

///|
type SourceSpan = (SourcePos, SourcePos)

///|
type SpannedToken = (Token, SourceSpan)

///|
/// Parser error type
suberror ParseError {
  SyntaxErrorAt(String, SourceSpan)
} derive(Debug)

///|
priv enum Token {
  IntTok(Int)
  StrTok(String)
  IdentTok(String)
  TrueTok
  FalseTok
  NilTok
  LetTok
  RecTok
  IfTok
  ThenTok
  ElseTok
  FnTok
  NotTok
  DoTok
  EndKeywordTok
  IsTok
  AndWordTok
  OrWordTok
  PlusTok
  MinusTok
  StarTok
  SlashTok
  PercentTok
  EqEqTok
  BangEqTok
  LtTok
  LeTok
  GtTok
  GeTok
  AndAndTok
  OrOrTok
  AssignTok
  ColonAssignTok
  PlusAssignTok
  MinusAssignTok
  StarAssignTok
  SlashAssignTok
  PercentAssignTok
  AndAndAssignTok
  OrOrAssignTok
  BangTok
  DotDotTok
  PipeTok
  DotTok
  HashTok
  LBraceTok
  RBraceTok
  LBracketTok
  RBracketTok
  LParenTok
  RParenTok
  SemicolonTok
  EndTok
} derive(Eq)

///|
impl Show for ParseError with output(self : ParseError, logger : &Logger) -> Unit {
  match self {
    SyntaxErrorAt(message, span) =>
      logger.write_string(
        "parse error: \{message} at \{format_source_span(span)}",
      )
  }
}

///|
pub fn parse(source : String) -> SurfaceExpr raise {
  let tokens = lex(source)
  let (expr, i) = parse_expr(tokens, 0)
  if i >= tokens.length() {
    raise SyntaxErrorAt("unexpected end", eof_span(tokens))
  }
  if token_kind(tokens, i) == EndTok {
    expr
  } else {
    raise SyntaxErrorAt(
      "unexpected token after expression: \{token_name(token_kind(tokens, i))}",
      token_span_at(tokens, i),
    )
  }
}

///|
pub fn parse_is_ok(source : String) -> Bool {
  try parse(source) catch {
    _ => false
  } noraise {
    _ => true
  }
}

///|
pub fn parse_is_error(source : String) -> Bool {
  try parse(source) catch {
    _ => true
  } noraise {
    _ => false
  }
}

///|
pub fn eval_source(source : String) -> Value raise {
  eval(desugar(parse(source)))
}

///|
pub fn format_parse_error(error : ParseError) -> String {
  match error {
    SyntaxErrorAt(message, span) => "\{message} at \{format_source_span(span)}"
  }
}

///|
pub fn parse_error_text(source : String) -> String? {
  try parse(source) catch {
    SyntaxErrorAt(message, span) =>
      Some("\{message} at \{format_source_span(span)}")
    _ => None
  } noraise {
    _ => None
  }
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
fn lex(source : String) -> Array[SpannedToken] raise {
  let tokens = []
  lex_loop(source, 0, 1, 1, tokens)
  let eof = (source.length(), 1, 1)
  let eof_pos = advance_position_range(source, 0, source.length(), eof)
  tokens.push((EndTok, (eof_pos, eof_pos)))
  tokens
}

///|
fn lex_loop(
  source : String,
  i : Int,
  line : Int,
  column : Int,
  acc : Array[SpannedToken],
) -> Unit raise {
  if i >= source.length() {
    return
  }
  let c = source.unsafe_get(i).unsafe_to_char()
  if c.is_ascii_whitespace() {
    let next = advance_position(source, i, line, column)
    let (next_line, next_column) = next
    return lex_loop(source, i + 1, next_line, next_column, acc)
  }
  if c.is_ascii_digit() {
    let end = scan_digits(source, i)
    let num_text = source[i:end].to_string()
    let value = parse_digits_to_int(num_text, 0, 0)
    let span = make_span(source, i, end, line, column)
    acc.push((IntTok(value), span))
    let (_, end_pos) = span
    let (_, next_line, next_column) = end_pos
    return lex_loop(source, end, next_line, next_column, acc)
  }
  if is_ident_start(c) {
    let end = scan_ident(source, i)
    let text = source[i:end].to_string()
    let tok = keyword_or_ident(text)
    let span = make_span(source, i, end, line, column)
    acc.push((tok, span))
    let (_, end_pos) = span
    let (_, next_line, next_column) = end_pos
    return lex_loop(source, end, next_line, next_column, acc)
  }
  match c {
    '"' => {
      let (content, end) = lex_string_content(
        source,
        i,
        line,
        column,
        "",
        i + 1,
      )
      let span = make_span(source, i, end + 1, line, column)
      acc.push((StrTok(content), span))
      let (_, end_pos) = span
      let (_, next_line, next_column) = end_pos
      lex_loop(source, end + 1, next_line, next_column, acc)
    }
    '(' => push_single_char_token(source, i, line, column, LParenTok, acc)
    ')' => push_single_char_token(source, i, line, column, RParenTok, acc)
    ';' => push_single_char_token(source, i, line, column, SemicolonTok, acc)
    '+' =>
      if i + 1 < source.length() &&
        source.unsafe_get(i + 1).unsafe_to_char() == '=' {
        push_multi_char_token(
          source,
          i,
          i + 2,
          line,
          column,
          PlusAssignTok,
          acc,
        )
      } else {
        push_single_char_token(source, i, line, column, PlusTok, acc)
      }
    '-' =>
      if i + 1 < source.length() &&
        source.unsafe_get(i + 1).unsafe_to_char() == '=' {
        push_multi_char_token(
          source,
          i,
          i + 2,
          line,
          column,
          MinusAssignTok,
          acc,
        )
      } else {
        push_single_char_token(source, i, line, column, MinusTok, acc)
      }
    '*' =>
      if i + 1 < source.length() &&
        source.unsafe_get(i + 1).unsafe_to_char() == '=' {
        push_multi_char_token(
          source,
          i,
          i + 2,
          line,
          column,
          StarAssignTok,
          acc,
        )
      } else {
        push_single_char_token(source, i, line, column, StarTok, acc)
      }
    '/' =>
      if i + 1 < source.length() &&
        source.unsafe_get(i + 1).unsafe_to_char() == '=' {
        push_multi_char_token(
          source,
          i,
          i + 2,
          line,
          column,
          SlashAssignTok,
          acc,
        )
      } else {
        push_single_char_token(source, i, line, column, SlashTok, acc)
      }
    '%' =>
      if i + 1 < source.length() &&
        source.unsafe_get(i + 1).unsafe_to_char() == '=' {
        push_multi_char_token(
          source,
          i,
          i + 2,
          line,
          column,
          PercentAssignTok,
          acc,
        )
      } else {
        push_single_char_token(source, i, line, column, PercentTok, acc)
      }
    '>' =>
      if i + 1 < source.length() &&
        source.unsafe_get(i + 1).unsafe_to_char() == '=' {
        push_multi_char_token(source, i, i + 2, line, column, GeTok, acc)
      } else {
        push_single_char_token(source, i, line, column, GtTok, acc)
      }
    '<' =>
      if i + 1 < source.length() &&
        source.unsafe_get(i + 1).unsafe_to_char() == '=' {
        push_multi_char_token(source, i, i + 2, line, column, LeTok, acc)
      } else {
        push_single_char_token(source, i, line, column, LtTok, acc)
      }
    '=' =>
      if i + 1 < source.length() {
        let n = source.unsafe_get(i + 1).unsafe_to_char()
        if n == '=' {
          push_multi_char_token(source, i, i + 2, line, column, EqEqTok, acc)
        } else {
          push_single_char_token(source, i, line, column, AssignTok, acc)
        }
      } else {
        push_single_char_token(source, i, line, column, AssignTok, acc)
      }
    ':' =>
      if i + 1 < source.length() &&
        source.unsafe_get(i + 1).unsafe_to_char() == '=' {
        push_multi_char_token(
          source,
          i,
          i + 2,
          line,
          column,
          ColonAssignTok,
          acc,
        )
      } else {
        let span = make_span(source, i, i + 1, line, column)
        raise SyntaxErrorAt("unexpected character: \{c}", span)
      }
    '!' =>
      if i + 1 < source.length() &&
        source.unsafe_get(i + 1).unsafe_to_char() == '=' {
        push_multi_char_token(source, i, i + 2, line, column, BangEqTok, acc)
      } else {
        push_single_char_token(source, i, line, column, BangTok, acc)
      }
    '.' =>
      if i + 1 < source.length() &&
        source.unsafe_get(i + 1).unsafe_to_char() == '.' {
        push_multi_char_token(source, i, i + 2, line, column, DotDotTok, acc)
      } else {
        push_single_char_token(source, i, line, column, DotTok, acc)
      }
    '|' =>
      if i + 1 < source.length() &&
        source.unsafe_get(i + 1).unsafe_to_char() == '|' {
        if i + 2 < source.length() &&
          source.unsafe_get(i + 2).unsafe_to_char() == '=' {
          push_multi_char_token(
            source,
            i,
            i + 3,
            line,
            column,
            OrOrAssignTok,
            acc,
          )
        } else {
          push_multi_char_token(source, i, i + 2, line, column, OrOrTok, acc)
        }
      } else {
        push_single_char_token(source, i, line, column, PipeTok, acc)
      }
    '#' => push_single_char_token(source, i, line, column, HashTok, acc)
    '{' => push_single_char_token(source, i, line, column, LBraceTok, acc)
    '}' => push_single_char_token(source, i, line, column, RBraceTok, acc)
    '[' => push_single_char_token(source, i, line, column, LBracketTok, acc)
    ']' => push_single_char_token(source, i, line, column, RBracketTok, acc)
    '&' =>
      if i + 1 < source.length() &&
        source.unsafe_get(i + 1).unsafe_to_char() == '&' {
        if i + 2 < source.length() &&
          source.unsafe_get(i + 2).unsafe_to_char() == '=' {
          push_multi_char_token(
            source,
            i,
            i + 3,
            line,
            column,
            AndAndAssignTok,
            acc,
          )
        } else {
          push_multi_char_token(source, i, i + 2, line, column, AndAndTok, acc)
        }
      } else {
        raise SyntaxErrorAt(
          "unexpected token '&'",
          make_span(source, i, i + 1, line, column),
        )
      }
    _ =>
      raise SyntaxErrorAt(
        "unexpected character: \{c}",
        make_span(source, i, i + 1, line, column),
      )
  }
}

///|
fn push_single_char_token(
  source : String,
  i : Int,
  line : Int,
  column : Int,
  token : Token,
  acc : Array[SpannedToken],
) -> Unit raise {
  let span = make_span(source, i, i + 1, line, column)
  acc.push((token, span))
  let (_, end_pos) = span
  let (_, next_line, next_column) = end_pos
  lex_loop(source, i + 1, next_line, next_column, acc)
}

///|
fn push_multi_char_token(
  source : String,
  start : Int,
  end_ : Int,
  line : Int,
  column : Int,
  token : Token,
  acc : Array[SpannedToken],
) -> Unit raise {
  let span = make_span(source, start, end_, line, column)
  acc.push((token, span))
  let (_, end_pos) = span
  let (_, next_line, next_column) = end_pos
  lex_loop(source, end_, next_line, next_column, acc)
}

///|
fn advance_position(
  source : String,
  i : Int,
  line : Int,
  column : Int,
) -> (Int, Int) {
  if i >= source.length() {
    return (line, column)
  }
  let c = source.unsafe_get(i).unsafe_to_char()
  if c == '\n' {
    (line + 1, 1)
  } else {
    (line, column + 1)
  }
}

///|
fn advance_position_range(
  source : String,
  i : Int,
  end_ : Int,
  start : SourcePos,
) -> SourcePos {
  let (offset, line, column) = start
  if i >= end_ {
    return (offset + (end_ - i), line, column)
  }
  let (next_line, next_column) = advance_position(source, i, line, column)
  advance_position_range(
    source,
    i + 1,
    end_,
    (offset + 1, next_line, next_column),
  )
}

///|
fn make_span(
  source : String,
  start_offset : Int,
  end_offset : Int,
  line : Int,
  column : Int,
) -> SourceSpan {
  let start = (start_offset, line, column)
  let end_ = advance_position_range(source, start_offset, end_offset, start)
  (start, end_)
}

///|
fn token_kind(tokens : Array[SpannedToken], i : Int) -> Token {
  let (tok, _) = tokens[i]
  tok
}

///|
fn token_span_at(tokens : Array[SpannedToken], i : Int) -> SourceSpan {
  if i < tokens.length() {
    let (_, span) = tokens[i]
    span
  } else {
    eof_span(tokens)
  }
}

///|
fn eof_span(tokens : Array[SpannedToken]) -> SourceSpan {
  let (_, span) = tokens[tokens.length() - 1]
  span
}

///|
fn format_source_span(span : SourceSpan) -> String {
  let (start, end_) = span
  let (_, start_line, start_column) = start
  let (_, end_line, end_column) = end_
  if start_line == end_line {
    "\{start_line}:\{start_column}-\{end_column}"
  } else {
    "\{start_line}:\{start_column}-\{end_line}:\{end_column}"
  }
}

///|
fn expr_span(
  tokens : Array[SpannedToken],
  start_i : Int,
  end_i : Int,
) -> SourceSpan {
  let start_span = token_span_at(tokens, start_i)
  let end_span = token_span_at(tokens, end_i - 1)
  let (start_pos, _) = start_span
  let (_, end_pos) = end_span
  (start_pos, end_pos)
}

///|
fn located_expr(
  tokens : Array[SpannedToken],
  start_i : Int,
  end_i : Int,
  expr : SurfaceExpr,
) -> SurfaceExpr {
  SLocated(expr_span(tokens, start_i, end_i), expr)
}

///|
fn located_expr_from_left(
  left : SurfaceExpr,
  tokens : Array[SpannedToken],
  end_i : Int,
  expr : SurfaceExpr,
) -> SurfaceExpr {
  let (start_pos, _) = expr_known_span(left)
  let (_, end_pos) = token_span_at(tokens, end_i - 1)
  SLocated((start_pos, end_pos), expr)
}

///|
fn expr_known_span(expr : SurfaceExpr) -> SourceSpan {
  match expr {
    SLocated(span, _) => span
    _ => ((0, 1, 1), (0, 1, 1))
  }
}

///|
fn[T] syntax_error_at(
  tokens : Array[SpannedToken],
  i : Int,
  message : String,
) -> T raise {
  raise SyntaxErrorAt(message, token_span_at(tokens, i))
}

///|
fn[T] syntax_error_eof(
  tokens : Array[SpannedToken],
  message : String,
) -> T raise {
  raise SyntaxErrorAt(message, eof_span(tokens))
}

///|
fn scan_digits(source : String, i : Int) -> Int {
  if i >= source.length() {
    return i
  }
  let c = source.unsafe_get(i).unsafe_to_char()
  if c.is_ascii_digit() {
    scan_digits(source, i + 1)
  } else {
    i
  }
}

///|
fn scan_ident(source : String, i : Int) -> Int {
  if i >= source.length() {
    return i
  }
  let c = source.unsafe_get(i).unsafe_to_char()
  if is_ident_continue(c) {
    scan_ident(source, i + 1)
  } else {
    i
  }
}

///|
fn lex_string_content(
  source : String,
  start : Int,
  line : Int,
  column : Int,
  acc : String,
  i : Int,
) -> (String, Int) raise {
  if i >= source.length() {
    raise SyntaxErrorAt(
      "unterminated string literal",
      make_span(source, start, source.length(), line, column),
    )
  }
  let c = source.unsafe_get(i).unsafe_to_char()
  if c == '"' {
    return (acc, i)
  }
  if c == '\\' {
    return lex_string_escape(source, start, line, column, acc, i)
  }
  lex_string_content(
    source,
    start,
    line,
    column,
    "\{acc}\{source[i:i + 1]}",
    i + 1,
  )
}

///|
fn lex_string_escape(
  source : String,
  start : Int,
  line : Int,
  column : Int,
  acc : String,
  i : Int,
) -> (String, Int) raise {
  let escape_pos = advance_position_range(
    source,
    start,
    i,
    (start, line, column),
  )
  let (_, escape_line, escape_column) = escape_pos
  if i + 1 >= source.length() {
    raise SyntaxErrorAt(
      "unterminated escape sequence in string literal",
      make_span(source, i, source.length(), escape_line, escape_column),
    )
  }
  let escaped = source.unsafe_get(i + 1).unsafe_to_char()
  let decoded = match escaped {
    'n' => "\n"
    'r' => "\r"
    't' => "\t"
    '"' => "\""
    '\\' => "\\"
    _ =>
      raise SyntaxErrorAt(
        "invalid escape sequence: \\\{escaped}",
        make_span(source, i, i + 2, escape_line, escape_column),
      )
  }
  lex_string_content(source, start, line, column, "\{acc}\{decoded}", i + 2)
}

///|
fn parse_digits_to_int(text : String, i : Int, acc : Int) -> Int {
  if i >= text.length() {
    return acc
  }
  let d = text.unsafe_get(i).unsafe_to_char().to_int() - '0'.to_int()
  parse_digits_to_int(text, i + 1, acc * 10 + d)
}

///|
fn is_ident_start(c : Char) -> Bool {
  c.is_ascii_alphabetic() || c == '_'
}

///|
fn is_ident_continue(c : Char) -> Bool {
  c.is_ascii_alphabetic() || c.is_ascii_digit() || c == '_'
}

///|
fn keyword_or_ident(text : String) -> Token {
  match text {
    "true" => TrueTok
    "false" => FalseTok
    "nil" => NilTok
    "let" => LetTok
    "rec" => RecTok
    "if" => IfTok
    "then" => ThenTok
    "else" => ElseTok
    "fn" => FnTok
    "not" => NotTok
    "do" => DoTok
    "end" => EndKeywordTok
    "is" => IsTok
    "and" => AndWordTok
    "or" => OrWordTok
    _ => IdentTok(text)
  }
}

///|
fn token_name(tok : Token) -> String {
  match tok {
    IntTok(_) => "int"
    StrTok(_) => "string"
    IdentTok(name) => "identifier(\{name})"
    TrueTok => "true"
    FalseTok => "false"
    NilTok => "nil"
    LetTok => "let"
    RecTok => "rec"
    IfTok => "if"
    ThenTok => "then"
    ElseTok => "else"
    FnTok => "fn"
    NotTok => "not"
    DoTok => "do"
    EndKeywordTok => "end"
    IsTok => "is"
    AndWordTok => "and"
    OrWordTok => "or"
    PlusTok => "+"
    MinusTok => "-"
    StarTok => "*"
    SlashTok => "/"
    PercentTok => "%"
    EqEqTok => "=="
    BangEqTok => "!="
    LtTok => "<"
    LeTok => "<="
    GtTok => ">"
    GeTok => ">="
    AndAndTok => "&&"
    OrOrTok => "||"
    AssignTok => "="
    ColonAssignTok => ":="
    PlusAssignTok => "+="
    MinusAssignTok => "-="
    StarAssignTok => "*="
    SlashAssignTok => "/="
    PercentAssignTok => "%="
    AndAndAssignTok => "&&="
    OrOrAssignTok => "||="
    BangTok => "!"
    DotDotTok => ".."
    PipeTok => "|"
    DotTok => "."
    HashTok => "#"
    LBraceTok => "{"
    RBraceTok => "}"
    LBracketTok => "["
    RBracketTok => "]"
    LParenTok => "("
    RParenTok => ")"
    SemicolonTok => ";"
    EndTok => "<eof>"
  }
}

///|
fn parse_expr(
  tokens : Array[SpannedToken],
  i : Int,
) -> (SurfaceExpr, Int) raise {
  let (expr, j) = parse_assign_expr(tokens, i)
  parse_trailing_apply_tail(expr, tokens, j)
}

///|
fn parse_assign_expr(
  tokens : Array[SpannedToken],
  i : Int,
) -> (SurfaceExpr, Int) raise {
  let (left, j) = parse_let_expr(tokens, i)
  if j >= tokens.length() {
    return (left, j)
  }
  match token_kind(tokens, j) {
    ColonAssignTok => {
      let (right, k) = parse_assign_expr(tokens, j + 1)
      (located_expr(tokens, i, k, SRefSet(left, right)), k)
    }
    PlusAssignTok => {
      let (right, k) = parse_assign_expr(tokens, j + 1)
      (located_expr(tokens, i, k, SRefUpdate(Add, left, right)), k)
    }
    MinusAssignTok => {
      let (right, k) = parse_assign_expr(tokens, j + 1)
      (located_expr(tokens, i, k, SRefUpdate(Sub, left, right)), k)
    }
    StarAssignTok => {
      let (right, k) = parse_assign_expr(tokens, j + 1)
      (located_expr(tokens, i, k, SRefUpdate(Mul, left, right)), k)
    }
    SlashAssignTok => {
      let (right, k) = parse_assign_expr(tokens, j + 1)
      (located_expr(tokens, i, k, SRefUpdate(Div, left, right)), k)
    }
    PercentAssignTok => {
      let (right, k) = parse_assign_expr(tokens, j + 1)
      (located_expr(tokens, i, k, SRefUpdate(Mod, left, right)), k)
    }
    AndAndAssignTok => {
      let (right, k) = parse_assign_expr(tokens, j + 1)
      (located_expr(tokens, i, k, SRefUpdate(And, left, right)), k)
    }
    OrOrAssignTok => {
      let (right, k) = parse_assign_expr(tokens, j + 1)
      (located_expr(tokens, i, k, SRefUpdate(Or, left, right)), k)
    }
    _ => (left, j)
  }
}

///|
fn let_compound_assign_binop(tok : Token) -> BinOp? {
  match tok {
    PlusAssignTok => Some(Add)
    MinusAssignTok => Some(Sub)
    StarAssignTok => Some(Mul)
    SlashAssignTok => Some(Div)
    PercentAssignTok => Some(Mod)
    AndAndAssignTok => Some(And)
    OrOrAssignTok => Some(Or)
    _ => None
  }
}

///|
priv enum ParsedLetBinding {
  PLetPattern(SurfacePattern, SurfaceExpr)
  PLetFun(String, Array[SurfaceParam], SurfaceExpr)
}

///|
fn parse_plain_let_binding(
  tokens : Array[SpannedToken],
  i : Int,
) -> (ParsedLetBinding, Int) raise {
  if i >= tokens.length() {
    syntax_error_eof(tokens, "expected pattern after 'let'")
  }
  match token_kind(tokens, i) {
    IdentTok(name) =>
      if i + 1 < tokens.length() && token_kind(tokens, i + 1) == LParenTok {
        let (params, j) = parse_params(tokens, i + 2)
        if j >= tokens.length() || token_kind(tokens, j) != AssignTok {
          syntax_error_at(tokens, j, "expected '=' after let function params")
        }
        let (func_body, k) = parse_expr(tokens, j + 1)
        (PLetFun(name, params, func_body), k)
      } else if i + 1 < tokens.length() {
        match let_compound_assign_binop(token_kind(tokens, i + 1)) {
          Some(op) => {
            let (rhs_expr, k) = parse_expr(tokens, i + 2)
            let lhs_var = located_expr(tokens, i, i + 1, SVar(name))
            let value_expr = located_expr(
              tokens,
              i,
              k,
              SBinary(op, lhs_var, rhs_expr),
            )
            (PLetPattern(SPBind(name), value_expr), k)
          }
          None => {
            let (pattern, j) = parse_pattern(tokens, i)
            if j >= tokens.length() || token_kind(tokens, j) != AssignTok {
              syntax_error_at(tokens, j, "expected '=' after let pattern")
            }
            let (value_expr, k) = parse_expr(tokens, j + 1)
            (PLetPattern(pattern, value_expr), k)
          }
        }
      } else {
        let (pattern, j) = parse_pattern(tokens, i)
        if j >= tokens.length() || token_kind(tokens, j) != AssignTok {
          syntax_error_at(tokens, j, "expected '=' after let pattern")
        }
        let (value_expr, k) = parse_expr(tokens, j + 1)
        (PLetPattern(pattern, value_expr), k)
      }
    _ => {
      let (pattern, j) = parse_pattern(tokens, i)
      if j >= tokens.length() || token_kind(tokens, j) != AssignTok {
        syntax_error_at(tokens, j, "expected '=' after let pattern")
      }
      let (value_expr, k) = parse_expr(tokens, j + 1)
      (PLetPattern(pattern, value_expr), k)
    }
  }
}

///|
fn let_binding_to_pair(
  binding : ParsedLetBinding,
  tokens : Array[SpannedToken],
  start_i : Int,
  end_i : Int,
) -> (SurfacePattern, SurfaceExpr) {
  match binding {
    PLetPattern(pattern, value_expr) => (pattern, value_expr)
    PLetFun(name, params, func_body) =>
      (
        SPBind(name),
        located_expr(tokens, start_i, end_i, SLambda(params, func_body)),
      )
  }
}

///|
fn parse_plain_let_and_bindings(
  tokens : Array[SpannedToken],
  i : Int,
  acc : Array[(SurfacePattern, SurfaceExpr)],
) -> (Array[(SurfacePattern, SurfaceExpr)], Int) raise {
  if i >= tokens.length() {
    syntax_error_eof(tokens, "expected binding after 'and'")
  }
  let (binding, j) = parse_plain_let_binding(tokens, i)
  let pair = let_binding_to_pair(binding, tokens, i, j)
  if j < tokens.length() && token_kind(tokens, j) == AndWordTok {
    parse_plain_let_and_bindings(tokens, j + 1, acc + [pair])
  } else {
    (acc + [pair], j)
  }
}

///|
fn parse_let_rec_fun_binding(
  tokens : Array[SpannedToken],
  i : Int,
) -> ((String, Array[SurfaceParam], SurfaceExpr), Int) raise {
  if i >= tokens.length() {
    syntax_error_eof(tokens, "expected function name after 'let rec'")
  }
  match token_kind(tokens, i) {
    IdentTok(name) => {
      if i + 1 >= tokens.length() || token_kind(tokens, i + 1) != LParenTok {
        syntax_error_at(
          tokens,
          i + 1,
          "expected '(...)' after let rec function name",
        )
      }
      let (params, j) = parse_params(tokens, i + 2)
      if j >= tokens.length() || token_kind(tokens, j) != AssignTok {
        syntax_error_at(tokens, j, "expected '=' after let rec params")
      }
      let (func_body, k) = parse_expr(tokens, j + 1)
      ((name, params, func_body), k)
    }
    _ => syntax_error_at(tokens, i, "expected function name after 'let rec'")
  }
}

///|
fn parse_let_rec_and_defs(
  tokens : Array[SpannedToken],
  i : Int,
  acc : Array[(String, Array[SurfaceParam], SurfaceExpr)],
) -> (Array[(String, Array[SurfaceParam], SurfaceExpr)], Int) raise {
  if i >= tokens.length() {
    syntax_error_eof(tokens, "expected function name after 'and' in let rec")
  }
  let (def, j) = parse_let_rec_fun_binding(tokens, i)
  if j < tokens.length() && token_kind(tokens, j) == AndWordTok {
    parse_let_rec_and_defs(tokens, j + 1, acc + [def])
  } else {
    (acc + [def], j)
  }
}

///|
fn parse_let_expr(
  tokens : Array[SpannedToken],
  i : Int,
) -> (SurfaceExpr, Int) raise {
  if i >= tokens.length() {
    syntax_error_eof(tokens, "unexpected end")
  }
  if token_kind(tokens, i) == LetTok {
    if i + 1 < tokens.length() && token_kind(tokens, i + 1) == RecTok {
      parse_let_rec_expr(tokens, i + 2)
    } else {
      parse_plain_let_expr(tokens, i + 1)
    }
  } else if token_kind(tokens, i) == DoTok {
    parse_do_expr(tokens, i + 1)
  } else {
    parse_if_expr(tokens, i)
  }
}

///|
fn parse_plain_let_expr(
  tokens : Array[SpannedToken],
  i : Int,
) -> (SurfaceExpr, Int) raise {
  let (first_binding, j) = parse_plain_let_binding(tokens, i)
  if j < tokens.length() && token_kind(tokens, j) == AndWordTok {
    let first_pair = let_binding_to_pair(first_binding, tokens, i, j)
    let (rest_bindings, k) = parse_plain_let_and_bindings(tokens, j + 1, [])
    if k >= tokens.length() || token_kind(tokens, k) != SemicolonTok {
      syntax_error_at(tokens, k, "expected ';' after let binding")
    }
    let (body, m) = parse_expr(tokens, k + 1)
    (located_expr(tokens, i, m, SLetAnd([first_pair] + rest_bindings, body)), m)
  } else {
    if j >= tokens.length() || token_kind(tokens, j) != SemicolonTok {
      syntax_error_at(tokens, j, "expected ';' after let binding")
    }
    let (body, m) = parse_expr(tokens, j + 1)
    match first_binding {
      PLetFun(name, params, func_body) =>
        (located_expr(tokens, i, m, SLetFun(name, params, func_body, body)), m)
      PLetPattern(pattern, value_expr) =>
        (located_expr(tokens, i, m, SLet(pattern, value_expr, body)), m)
    }
  }
}

///|
fn parse_let_rec_expr(
  tokens : Array[SpannedToken],
  i : Int,
) -> (SurfaceExpr, Int) raise {
  let (first_def, j) = parse_let_rec_fun_binding(tokens, i)
  if j < tokens.length() && token_kind(tokens, j) == AndWordTok {
    let (rest_defs, k) = parse_let_rec_and_defs(tokens, j + 1, [])
    if k >= tokens.length() || token_kind(tokens, k) != SemicolonTok {
      syntax_error_at(tokens, k, "expected ';' after let rec binding")
    }
    let (body, m) = parse_expr(tokens, k + 1)
    (located_expr(tokens, i, m, SLetRecAnd([first_def] + rest_defs, body)), m)
  } else {
    let (name, params, func_body) = first_def
    if j >= tokens.length() || token_kind(tokens, j) != SemicolonTok {
      syntax_error_at(tokens, j, "expected ';' after let rec binding")
    }
    let (body, m) = parse_expr(tokens, j + 1)
    (located_expr(tokens, i, m, SLetRec(name, params, func_body, body)), m)
  }
}

///|
fn parse_do_expr(
  tokens : Array[SpannedToken],
  i : Int,
) -> (SurfaceExpr, Int) raise {
  if i >= tokens.length() {
    syntax_error_eof(tokens, "expected expression after 'do'")
  }
  let (value_expr, j) = parse_expr(tokens, i)
  if j >= tokens.length() || token_kind(tokens, j) != SemicolonTok {
    syntax_error_at(tokens, j, "expected ';' after do expression")
  }
  let (body, k) = parse_expr(tokens, j + 1)
  (located_expr(tokens, i, k, SDo(value_expr, body)), k)
}

///|
fn parse_if_expr(
  tokens : Array[SpannedToken],
  i : Int,
) -> (SurfaceExpr, Int) raise {
  if i < tokens.length() && token_kind(tokens, i) == IfTok {
    let has_leading_pipe = i + 1 < tokens.length() &&
      token_kind(tokens, i + 1) == PipeTok
    let case_i = if has_leading_pipe { i + 2 } else { i + 1 }
    let (first_arm, j, first_is_multi_route_is) = parse_if_first_cond_arm(
      tokens, case_i,
    )
    if is_if_single_route_mode(has_leading_pipe, first_is_multi_route_is) {
      let (closed_first_arm, end_i) = close_single_route_if_is(
        tokens, first_arm, j,
      )
      return (
        located_expr(
          tokens,
          i,
          end_i,
          SIf([closed_first_arm], located_expr(tokens, i, end_i, SNilLit)),
        ),
        end_i,
      )
    }
    let (rest_arms, else_expr, end_i) = parse_if_tail(tokens, j)
    (
      located_expr(tokens, i, end_i, SIf([first_arm] + rest_arms, else_expr)),
      end_i,
    )
  } else {
    parse_lambda_expr(tokens, i)
  }
}

///|
fn is_if_single_route_mode(
  has_leading_pipe : Bool,
  first_is_multi_route_is : Bool,
) -> Bool {
  !has_leading_pipe && first_is_multi_route_is
}

///|
fn parse_if_first_cond_arm(
  tokens : Array[SpannedToken],
  i : Int,
) -> (SurfaceIfCondArm, Int, Bool) raise {
  let (head_expr, j) = parse_expr(tokens, i)
  if j < tokens.length() && token_kind(tokens, j) == IsTok {
    let first_is_multi_route_is = j + 1 < tokens.length() &&
      token_kind(tokens, j + 1) == PipeTok
    let (arm_guard, end_i) = parse_if_is_guard(tokens, head_expr, j + 1)
    return (
      SIfCondArm(located_expr(tokens, i, j, SBoolLit(true)), arm_guard),
      end_i,
      first_is_multi_route_is,
    )
  }
  let (arm_guard, end_i) = parse_if_guard_after_value(tokens, head_expr, j)
  (SIfCondArm(head_expr, arm_guard), end_i, false)
}

///|
fn close_single_route_if_is(
  tokens : Array[SpannedToken],
  first_arm : SurfaceIfCondArm,
  i : Int,
) -> (SurfaceIfCondArm, Int) raise {
  match first_arm {
    SIfCondArm(cond, SIfIs(value_expr, arms)) =>
      if i < tokens.length() && token_kind(tokens, i) == ElseTok {
        let (body, j) = parse_expr(tokens, i + 1)
        (
          SIfCondArm(
            cond,
            SIfIs(
              value_expr,
              arms + [SIfPatternArm(SPBind("_"), SIfThen(body))],
            ),
          ),
          j,
        )
      } else if i < tokens.length() && token_kind(tokens, i) == EndKeywordTok {
        (
          SIfCondArm(
            cond,
            SIfIs(
              value_expr,
              [
                ..arms,
                SIfPatternArm(
                  SPBind("_"),
                  SIfThen(located_expr(tokens, i, i + 1, SNilLit)),
                ),
              ],
            ),
          ),
          i + 1,
        )
      } else {
        (first_arm, i)
      }
    _ => (first_arm, i)
  }
}

///|
fn parse_if_tail(
  tokens : Array[SpannedToken],
  i : Int,
) -> (Array[SurfaceIfCondArm], SurfaceExpr, Int) raise {
  if i >= tokens.length() {
    syntax_error_eof(tokens, "expected '|' or 'else' or 'end' in if expression")
  }
  if token_kind(tokens, i) == PipeTok {
    let (arm, j) = parse_if_cond_arm(tokens, i + 1)
    let (rest, else_expr, end_i) = parse_if_tail(tokens, j)
    ([arm] + rest, else_expr, end_i)
  } else if token_kind(tokens, i) == ElseTok {
    let (else_expr, j) = parse_expr(tokens, i + 1)
    ([], else_expr, j)
  } else if token_kind(tokens, i) == EndKeywordTok {
    ([], located_expr(tokens, i, i + 1, SNilLit), i + 1)
  } else {
    syntax_error_at(
      tokens, i, "expected '|' or 'else' or 'end' in if expression",
    )
  }
}

///|
fn parse_if_cond_arm(
  tokens : Array[SpannedToken],
  i : Int,
) -> (SurfaceIfCondArm, Int) raise {
  let (head_expr, j) = parse_expr(tokens, i)
  if j < tokens.length() && token_kind(tokens, j) == IsTok {
    let (arm_guard, end_i) = parse_if_is_guard(tokens, head_expr, j + 1)
    return (
      SIfCondArm(located_expr(tokens, i, j, SBoolLit(true)), arm_guard),
      end_i,
    )
  }
  let (arm_guard, end_i) = parse_if_guard_after_value(tokens, head_expr, j)
  (SIfCondArm(head_expr, arm_guard), end_i)
}

///|
fn parse_if_guard_after_value(
  tokens : Array[SpannedToken],
  _value_expr : SurfaceExpr,
  i : Int,
) -> (SurfaceIfGuard, Int) raise {
  if i >= tokens.length() {
    syntax_error_eof(tokens, "expected 'then' or 'and' or 'is' in if branch")
  }
  if token_kind(tokens, i) == ThenTok {
    let (body, j) = parse_expr(tokens, i + 1)
    return (SIfThen(body), j)
  }
  if token_kind(tokens, i) == AndWordTok {
    return parse_if_and_guard(tokens, i + 1)
  }
  syntax_error_at(tokens, i, "expected 'then' or 'and' or 'is' in if branch")
}

///|
fn parse_if_guard_after_pattern(
  tokens : Array[SpannedToken],
  i : Int,
) -> (SurfaceIfGuard, Int) raise {
  if i >= tokens.length() {
    syntax_error_eof(tokens, "expected 'then' or 'and' in pattern branch")
  }
  if token_kind(tokens, i) == ThenTok {
    let (body, j) = parse_expr(tokens, i + 1)
    return (SIfThen(body), j)
  }
  if token_kind(tokens, i) == AndWordTok {
    return parse_if_and_guard(tokens, i + 1)
  }
  syntax_error_at(tokens, i, "expected 'then' or 'and' in pattern branch")
}

///|
fn parse_if_and_guard(
  tokens : Array[SpannedToken],
  i : Int,
) -> (SurfaceIfGuard, Int) raise {
  if i >= tokens.length() {
    syntax_error_eof(tokens, "unexpected end after 'and'")
  }
  if token_kind(tokens, i) == PipeTok {
    let (first_arm, j) = parse_if_cond_arm(tokens, i + 1)
    let (rest, end_i) = parse_if_and_multi_tail(tokens, j)
    (SIfAnd([first_arm] + rest), end_i)
  } else {
    let (only_arm, j) = parse_if_cond_arm(tokens, i)
    (SIfAnd([only_arm]), j)
  }
}

///|
fn parse_if_and_multi_tail(
  tokens : Array[SpannedToken],
  i : Int,
) -> (Array[SurfaceIfCondArm], Int) raise {
  if i >= tokens.length() {
    syntax_error_eof(
      tokens, "expected '|' or 'or' or 'else' or 'end' after multi 'and' branch",
    )
  }
  if token_kind(tokens, i) == PipeTok {
    let (arm, j) = parse_if_cond_arm(tokens, i + 1)
    let (rest, end_i) = parse_if_and_multi_tail(tokens, j)
    ([arm] + rest, end_i)
  } else if token_kind(tokens, i) == OrWordTok {
    ([], i + 1)
  } else if token_kind(tokens, i) == ElseTok {
    let (body, j) = parse_expr(tokens, i + 1)
    (
      [
        SIfCondArm(
          located_expr(tokens, i, i + 1, SBoolLit(true)),
          SIfThen(body),
        ),
      ],
      j,
    )
  } else if token_kind(tokens, i) == EndKeywordTok {
    (
      [
        SIfCondArm(
          located_expr(tokens, i, i + 1, SBoolLit(true)),
          SIfThen(located_expr(tokens, i, i + 1, SNilLit)),
        ),
      ],
      i + 1,
    )
  } else {
    syntax_error_at(
      tokens, i, "expected '|' or 'or' or 'else' or 'end' after multi 'and' branch",
    )
  }
}

///|
fn parse_if_is_guard(
  tokens : Array[SpannedToken],
  value_expr : SurfaceExpr,
  i : Int,
) -> (SurfaceIfGuard, Int) raise {
  if i >= tokens.length() {
    syntax_error_eof(tokens, "unexpected end after 'is'")
  }
  if token_kind(tokens, i) == PipeTok {
    let (first_arm, j) = parse_if_pattern_arm(tokens, i + 1)
    let (rest, end_i) = parse_if_is_multi_tail(tokens, j)
    (SIfIs(value_expr, [first_arm] + rest), end_i)
  } else {
    let (only_arm, j) = parse_if_pattern_arm(tokens, i)
    (SIfIs(value_expr, [only_arm]), j)
  }
}

///|
fn parse_if_pattern_arm(
  tokens : Array[SpannedToken],
  i : Int,
) -> (SurfaceIfPatternArm, Int) raise {
  let (pattern, j) = parse_pattern(tokens, i)
  let (arm_guard, end_i) = parse_if_guard_after_pattern(tokens, j)
  (SIfPatternArm(pattern, arm_guard), end_i)
}

///|
fn parse_if_is_multi_tail(
  tokens : Array[SpannedToken],
  i : Int,
) -> (Array[SurfaceIfPatternArm], Int) raise {
  if i >= tokens.length() {
    syntax_error_eof(
      tokens, "expected '|' or 'or' or 'else' or 'end' after multi 'is' branch",
    )
  }
  if token_kind(tokens, i) == PipeTok {
    let (arm, j) = parse_if_pattern_arm(tokens, i + 1)
    let (rest, end_i) = parse_if_is_multi_tail(tokens, j)
    ([arm] + rest, end_i)
  } else if token_kind(tokens, i) == OrWordTok {
    ([], i + 1)
  } else if token_kind(tokens, i) == ElseTok {
    let (body, j) = parse_expr(tokens, i + 1)
    ([SIfPatternArm(SPBind("_"), SIfThen(body))], j)
  } else if token_kind(tokens, i) == EndKeywordTok {
    (
      [
        SIfPatternArm(
          SPBind("_"),
          SIfThen(located_expr(tokens, i, i + 1, SNilLit)),
        ),
      ],
      i + 1,
    )
  } else {
    syntax_error_at(
      tokens, i, "expected '|' or 'or' or 'else' or 'end' after multi 'is' branch",
    )
  }
}

///|
fn parse_lambda_expr(
  tokens : Array[SpannedToken],
  i : Int,
) -> (SurfaceExpr, Int) raise {
  if i < tokens.length() && token_kind(tokens, i) == FnTok {
    if i + 1 >= tokens.length() || token_kind(tokens, i + 1) != LParenTok {
      syntax_error_at(tokens, i + 1, "expected '(' after 'fn'")
    }
    let (params, j) = parse_params(tokens, i + 2)
    if j >= tokens.length() || token_kind(tokens, j) != AssignTok {
      syntax_error_at(tokens, j, "expected '=' after lambda params")
    }
    let (body, k) = parse_expr(tokens, j + 1)
    (located_expr(tokens, i, k, SLambda(params, body)), k)
  } else {
    parse_or_expr(tokens, i)
  }
}

///|
fn parse_params(
  tokens : Array[SpannedToken],
  i : Int,
) -> (Array[SurfaceParam], Int) raise {
  if i >= tokens.length() {
    syntax_error_eof(tokens, "unexpected end in params")
  }
  if token_kind(tokens, i) == RParenTok {
    ([], i + 1)
  } else {
    parse_params_nonempty(tokens, i)
  }
}

///|
fn parse_params_nonempty(
  tokens : Array[SpannedToken],
  i : Int,
) -> (Array[SurfaceParam], Int) raise {
  parse_params_nonempty_from(tokens, i, false, [])
}

///|
fn parse_params_nonempty_from(
  tokens : Array[SpannedToken],
  i : Int,
  seen_default : Bool,
  acc : Array[SurfaceParam],
) -> (Array[SurfaceParam], Int) raise {
  let (param, next) = parse_param(tokens, i)
  let has_default = surface_param_has_default(param)
  if seen_default && !has_default {
    syntax_error_at(
      tokens, i, "required params must appear before default params",
    )
  }
  if next >= tokens.length() {
    syntax_error_eof(tokens, "unexpected end in params")
  }
  if token_kind(tokens, next) == SemicolonTok {
    parse_params_nonempty_from(
      tokens,
      next + 1,
      seen_default || has_default,
      acc + [param],
    )
  } else if token_kind(tokens, next) == RParenTok {
    (acc + [param], next + 1)
  } else {
    syntax_error_at(
      tokens,
      next,
      "unexpected token in params: \{token_name(token_kind(tokens, next))}",
    )
  }
}

///|
fn parse_param(
  tokens : Array[SpannedToken],
  i : Int,
) -> (SurfaceParam, Int) raise {
  if i + 1 < tokens.length() && token_kind(tokens, i + 1) == LParenTok {
    match token_kind(tokens, i) {
      IdentTok(name) =>
        match find_matching_rparen(tokens, i + 1, 0) {
          Some(close_i) if close_i + 1 < tokens.length() &&
            token_kind(tokens, close_i + 1) == AssignTok => {
            let (lambda_expr, j) = parse_named_lambda_sugar(
              tokens,
              name,
              i + 1,
              i,
            )
            return (SParam(SPBind(name), Some(lambda_expr)), j)
          }
          _ => ()
        }
      _ => ()
    }
  }
  let (pattern, j) = parse_pattern(tokens, i)
  if j < tokens.length() && token_kind(tokens, j) == AssignTok {
    let (default_expr, k) = parse_expr(tokens, j + 1)
    (SParam(pattern, Some(default_expr)), k)
  } else {
    (SParam(pattern, None), j)
  }
}

///|
fn surface_param_has_default(param : SurfaceParam) -> Bool {
  match param {
    SParam(_, default_expr) =>
      match default_expr {
        Some(_) => true
        None => false
      }
  }
}

///|
fn parse_or_expr(
  tokens : Array[SpannedToken],
  i : Int,
) -> (SurfaceExpr, Int) raise {
  let (left, j) = parse_and_expr(tokens, i)
  parse_or_tail(left, tokens, j)
}

///|
fn parse_or_tail(
  left : SurfaceExpr,
  tokens : Array[SpannedToken],
  i : Int,
) -> (SurfaceExpr, Int) raise {
  if i < tokens.length() && token_kind(tokens, i) == OrOrTok {
    let (right, j) = parse_and_expr(tokens, i + 1)
    parse_or_tail(
      located_expr_from_left(left, tokens, j, SBinary(Or, left, right)),
      tokens,
      j,
    )
  } else {
    (left, i)
  }
}

///|
fn parse_and_expr(
  tokens : Array[SpannedToken],
  i : Int,
) -> (SurfaceExpr, Int) raise {
  let (left, j) = parse_eq_expr(tokens, i)
  parse_and_tail(left, tokens, j)
}

///|
fn parse_and_tail(
  left : SurfaceExpr,
  tokens : Array[SpannedToken],
  i : Int,
) -> (SurfaceExpr, Int) raise {
  if i < tokens.length() && token_kind(tokens, i) == AndAndTok {
    let (right, j) = parse_eq_expr(tokens, i + 1)
    parse_and_tail(
      located_expr_from_left(left, tokens, j, SBinary(And, left, right)),
      tokens,
      j,
    )
  } else {
    (left, i)
  }
}

///|
fn parse_eq_expr(
  tokens : Array[SpannedToken],
  i : Int,
) -> (SurfaceExpr, Int) raise {
  let (left, j) = parse_cmp_expr(tokens, i)
  parse_eq_tail(left, tokens, j)
}

///|
fn parse_eq_tail(
  left : SurfaceExpr,
  tokens : Array[SpannedToken],
  i : Int,
) -> (SurfaceExpr, Int) raise {
  if i < tokens.length() && token_kind(tokens, i) == EqEqTok {
    let (right, j) = parse_cmp_expr(tokens, i + 1)
    parse_eq_tail(
      located_expr_from_left(left, tokens, j, SBinary(Eq, left, right)),
      tokens,
      j,
    )
  } else if i < tokens.length() && token_kind(tokens, i) == BangEqTok {
    let (right, j) = parse_cmp_expr(tokens, i + 1)
    parse_eq_tail(
      located_expr_from_left(left, tokens, j, SBinary(Ne, left, right)),
      tokens,
      j,
    )
  } else {
    (left, i)
  }
}

///|
fn parse_cmp_expr(
  tokens : Array[SpannedToken],
  i : Int,
) -> (SurfaceExpr, Int) raise {
  let (left, j) = parse_add_expr(tokens, i)
  parse_cmp_tail(left, tokens, j)
}

///|
fn parse_cmp_tail(
  left : SurfaceExpr,
  tokens : Array[SpannedToken],
  i : Int,
) -> (SurfaceExpr, Int) raise {
  if i < tokens.length() && token_kind(tokens, i) == LtTok {
    let (right, j) = parse_add_expr(tokens, i + 1)
    parse_cmp_tail(
      located_expr_from_left(left, tokens, j, SBinary(Lt, left, right)),
      tokens,
      j,
    )
  } else if i < tokens.length() && token_kind(tokens, i) == LeTok {
    let (right, j) = parse_add_expr(tokens, i + 1)
    parse_cmp_tail(
      located_expr_from_left(left, tokens, j, SBinary(Le, left, right)),
      tokens,
      j,
    )
  } else if i < tokens.length() && token_kind(tokens, i) == GtTok {
    let (right, j) = parse_add_expr(tokens, i + 1)
    parse_cmp_tail(
      located_expr_from_left(left, tokens, j, SBinary(Gt, left, right)),
      tokens,
      j,
    )
  } else if i < tokens.length() && token_kind(tokens, i) == GeTok {
    let (right, j) = parse_add_expr(tokens, i + 1)
    parse_cmp_tail(
      located_expr_from_left(left, tokens, j, SBinary(Ge, left, right)),
      tokens,
      j,
    )
  } else {
    (left, i)
  }
}

///|
fn parse_add_expr(
  tokens : Array[SpannedToken],
  i : Int,
) -> (SurfaceExpr, Int) raise {
  let (left, j) = parse_mul_expr(tokens, i)
  parse_add_tail(left, tokens, j)
}

///|
fn parse_add_tail(
  left : SurfaceExpr,
  tokens : Array[SpannedToken],
  i : Int,
) -> (SurfaceExpr, Int) raise {
  if i < tokens.length() && token_kind(tokens, i) == PlusTok {
    let (right, j) = parse_mul_expr(tokens, i + 1)
    parse_add_tail(
      located_expr_from_left(left, tokens, j, SBinary(Add, left, right)),
      tokens,
      j,
    )
  } else if i < tokens.length() && token_kind(tokens, i) == MinusTok {
    let (right, j) = parse_mul_expr(tokens, i + 1)
    parse_add_tail(
      located_expr_from_left(left, tokens, j, SBinary(Sub, left, right)),
      tokens,
      j,
    )
  } else {
    (left, i)
  }
}

///|
fn parse_mul_expr(
  tokens : Array[SpannedToken],
  i : Int,
) -> (SurfaceExpr, Int) raise {
  let (left, j) = parse_unary_expr(tokens, i)
  parse_mul_tail(left, tokens, j)
}

///|
fn parse_mul_tail(
  left : SurfaceExpr,
  tokens : Array[SpannedToken],
  i : Int,
) -> (SurfaceExpr, Int) raise {
  if i < tokens.length() && token_kind(tokens, i) == StarTok {
    let (right, j) = parse_unary_expr(tokens, i + 1)
    parse_mul_tail(
      located_expr_from_left(left, tokens, j, SBinary(Mul, left, right)),
      tokens,
      j,
    )
  } else if i < tokens.length() && token_kind(tokens, i) == SlashTok {
    let (right, j) = parse_unary_expr(tokens, i + 1)
    parse_mul_tail(
      located_expr_from_left(left, tokens, j, SBinary(Div, left, right)),
      tokens,
      j,
    )
  } else if i < tokens.length() && token_kind(tokens, i) == PercentTok {
    let (right, j) = parse_unary_expr(tokens, i + 1)
    parse_mul_tail(
      located_expr_from_left(left, tokens, j, SBinary(Mod, left, right)),
      tokens,
      j,
    )
  } else {
    (left, i)
  }
}

///|
fn parse_unary_expr(
  tokens : Array[SpannedToken],
  i : Int,
) -> (SurfaceExpr, Int) raise {
  if i < tokens.length() && token_kind(tokens, i) == BangTok {
    let (expr, j) = parse_unary_expr(tokens, i + 1)
    (located_expr(tokens, i, j, SRefGet(expr)), j)
  } else if i < tokens.length() && token_kind(tokens, i) == MinusTok {
    let (expr, j) = parse_unary_expr(tokens, i + 1)
    (located_expr(tokens, i, j, SUnary(Neg, expr)), j)
  } else if i < tokens.length() && token_kind(tokens, i) == NotTok {
    let (expr, j) = parse_unary_expr(tokens, i + 1)
    (located_expr(tokens, i, j, SUnary(Not, expr)), j)
  } else {
    parse_postfix_expr(tokens, i)
  }
}

///|
fn parse_trailing_apply_tail(
  expr : SurfaceExpr,
  tokens : Array[SpannedToken],
  i : Int,
) -> (SurfaceExpr, Int) raise {
  if is_trailing_arg_start(tokens, i) {
    let (arg_expr, j) = parse_expr(tokens, i)
    parse_trailing_apply_tail(
      append_trailing_arg(expr, arg_expr, tokens, j),
      tokens,
      j,
    )
  } else {
    (expr, i)
  }
}

///|
fn is_trailing_arg_start(tokens : Array[SpannedToken], i : Int) -> Bool {
  if i >= tokens.length() {
    return false
  }
  match token_kind(tokens, i) {
    LetTok
    | IfTok
    | FnTok
    | DoTok
    | BangTok
    | MinusTok
    | NotTok
    | IntTok(_)
    | StrTok(_)
    | TrueTok
    | FalseTok
    | NilTok
    | IdentTok(_)
    | HashTok
    | LBraceTok
    | LBracketTok
    | LParenTok => true
    _ => false
  }
}

///|
fn append_trailing_arg(
  expr : SurfaceExpr,
  arg_expr : SurfaceExpr,
  tokens : Array[SpannedToken],
  end_i : Int,
) -> SurfaceExpr {
  match expr {
    SLocated(_, SCall(func_expr, args)) =>
      located_expr_from_left(
        expr,
        tokens,
        end_i,
        SCall(func_expr, args + [SArgPos(arg_expr)]),
      )
    SCall(func_expr, args) =>
      located_expr_from_left(
        expr,
        tokens,
        end_i,
        SCall(func_expr, args + [SArgPos(arg_expr)]),
      )
    _ =>
      located_expr_from_left(
        expr,
        tokens,
        end_i,
        SCall(expr, [SArgPos(arg_expr)]),
      )
  }
}

///|
fn parse_postfix_expr(
  tokens : Array[SpannedToken],
  i : Int,
) -> (SurfaceExpr, Int) raise {
  let (expr, j) = parse_primary_expr(tokens, i)
  parse_postfix_tail(expr, tokens, j)
}

///|
fn parse_postfix_tail(
  expr : SurfaceExpr,
  tokens : Array[SpannedToken],
  i : Int,
) -> (SurfaceExpr, Int) raise {
  if i < tokens.length() && token_kind(tokens, i) == LParenTok {
    let (args, j) = parse_args(tokens, i + 1)
    parse_postfix_tail(
      located_expr_from_left(expr, tokens, j, SCall(expr, args)),
      tokens,
      j,
    )
  } else if i < tokens.length() && token_kind(tokens, i) == DotTok {
    if i + 1 >= tokens.length() {
      syntax_error_eof(tokens, "expected field name after '.'")
    }
    match token_kind(tokens, i + 1) {
      IdentTok(name) =>
        parse_postfix_tail(
          located_expr_from_left(expr, tokens, i + 2, SField(expr, name)),
          tokens,
          i + 2,
        )
      tok =>
        syntax_error_at(
          tokens,
          i + 1,
          "expected field name, found: \{token_name(tok)}",
        )
    }
  } else {
    (expr, i)
  }
}

///|
fn parse_args(
  tokens : Array[SpannedToken],
  i : Int,
) -> (Array[SurfaceCallArg], Int) raise {
  if i >= tokens.length() {
    syntax_error_eof(tokens, "unexpected end in args")
  }
  if token_kind(tokens, i) == RParenTok {
    ([], i + 1)
  } else {
    parse_args_nonempty(tokens, i)
  }
}

///|
fn parse_args_nonempty(
  tokens : Array[SpannedToken],
  i : Int,
) -> (Array[SurfaceCallArg], Int) raise {
  let args = []
  for j = i, _pos = 0 {
    let (arg, next_expr) = parse_call_arg(tokens, j)
    args.push(arg)
    if next_expr >= tokens.length() {
      syntax_error_eof(tokens, "unexpected end in args")
    }
    if token_kind(tokens, next_expr) == SemicolonTok {
      continue next_expr + 1, _pos + 1
    }
    if token_kind(tokens, next_expr) == RParenTok {
      break (args, next_expr + 1)
    }
    syntax_error_at(
      tokens,
      next_expr,
      "unexpected token in args: \{token_name(token_kind(tokens, next_expr))}",
    )
  }
}

///|
fn parse_call_arg(
  tokens : Array[SpannedToken],
  i : Int,
) -> (SurfaceCallArg, Int) raise {
  if i + 1 < tokens.length() && token_kind(tokens, i + 1) == AssignTok {
    match token_kind(tokens, i) {
      IdentTok(name) => {
        let (value_expr, j) = parse_expr(tokens, i + 2)
        return (SArgNamed(name, value_expr), j)
      }
      _ => ()
    }
  }
  if i + 1 < tokens.length() && token_kind(tokens, i + 1) == LParenTok {
    match token_kind(tokens, i) {
      IdentTok(name) =>
        match find_matching_rparen(tokens, i + 1, 0) {
          Some(close_i) if close_i + 1 < tokens.length() &&
            token_kind(tokens, close_i + 1) == AssignTok => {
            let (lambda_expr, j) = parse_named_lambda_sugar(
              tokens,
              name,
              i + 1,
              i,
            )
            return (SArgNamed(name, lambda_expr), j)
          }
          _ => ()
        }
      _ => ()
    }
  }
  let (expr, j) = parse_expr(tokens, i)
  (SArgPos(expr), j)
}

///|
fn find_matching_rparen(
  tokens : Array[SpannedToken],
  i : Int,
  depth : Int,
) -> Int? {
  if i >= tokens.length() {
    return None
  }
  let next_depth = match token_kind(tokens, i) {
    LParenTok => depth + 1
    RParenTok => depth - 1
    _ => depth
  }
  if next_depth == 0 {
    Some(i)
  } else {
    find_matching_rparen(tokens, i + 1, next_depth)
  }
}

///|
fn parse_named_lambda_sugar(
  tokens : Array[SpannedToken],
  _name : String,
  lparen_i : Int,
  start_i : Int,
) -> (SurfaceExpr, Int) raise {
  let (params, j) = parse_params(tokens, lparen_i + 1)
  if j >= tokens.length() || token_kind(tokens, j) != AssignTok {
    syntax_error_at(tokens, j, "expected '=' after function params")
  }
  let (func_body, k) = parse_expr(tokens, j + 1)
  (located_expr(tokens, start_i, k, SLambda(params, func_body)), k)
}

///|
fn parse_primary_expr(
  tokens : Array[SpannedToken],
  i : Int,
) -> (SurfaceExpr, Int) raise {
  if i >= tokens.length() {
    syntax_error_eof(tokens, "unexpected end")
  }
  match token_kind(tokens, i) {
    IntTok(v) => (located_expr(tokens, i, i + 1, SIntLit(v)), i + 1)
    StrTok(v) => (located_expr(tokens, i, i + 1, SStringLit(v)), i + 1)
    TrueTok => (located_expr(tokens, i, i + 1, SBoolLit(true)), i + 1)
    FalseTok => (located_expr(tokens, i, i + 1, SBoolLit(false)), i + 1)
    NilTok => (located_expr(tokens, i, i + 1, SNilLit), i + 1)
    IdentTok(name) => (located_expr(tokens, i, i + 1, SVar(name)), i + 1)
    HashTok => parse_variant_literal(tokens, i + 1)
    LBraceTok => parse_record_literal(tokens, i + 1)
    LBracketTok => parse_list_literal(tokens, i + 1)
    LParenTok => {
      let (expr, j) = parse_expr(tokens, i + 1)
      if j < tokens.length() && token_kind(tokens, j) == RParenTok {
        (located_expr(tokens, i, j + 1, expr), j + 1)
      } else if j < tokens.length() {
        syntax_error_at(
          tokens,
          j,
          "expected ')', found: \{token_name(token_kind(tokens, j))}",
        )
      } else {
        syntax_error_eof(tokens, "expected ')' but found end")
      }
    }
    tok => syntax_error_at(tokens, i, "unexpected token: \{token_name(tok)}")
  }
}

///|
fn parse_variant_literal(
  tokens : Array[SpannedToken],
  i : Int,
) -> (SurfaceExpr, Int) raise {
  if i >= tokens.length() {
    syntax_error_eof(tokens, "expected variant name after '#'")
  }
  match token_kind(tokens, i) {
    IdentTok(tag) => {
      if i + 1 >= tokens.length() || token_kind(tokens, i + 1) != LParenTok {
        syntax_error_at(tokens, i + 1, "expected '(' after variant tag")
      }
      let (value_expr, j) = parse_expr(tokens, i + 2)
      if j >= tokens.length() || token_kind(tokens, j) != RParenTok {
        syntax_error_at(tokens, j, "expected ')' after variant payload")
      }
      (located_expr(tokens, i - 1, j + 1, SVariant(tag, value_expr)), j + 1)
    }
    tok =>
      syntax_error_at(
        tokens,
        i,
        "expected variant name, found: \{token_name(tok)}",
      )
  }
}

///|
fn parse_record_literal(
  tokens : Array[SpannedToken],
  i : Int,
) -> (SurfaceExpr, Int) raise {
  if i < tokens.length() && token_kind(tokens, i) == RBraceTok {
    return (located_expr(tokens, i - 1, i + 1, SRecord([])), i + 1)
  }
  let fields = []
  for j = i, _pos = 0 {
    if j >= tokens.length() {
      syntax_error_eof(tokens, "unexpected end in record")
    }
    let name = match token_kind(tokens, j) {
      IdentTok(field_name) => field_name
      tok =>
        syntax_error_at(
          tokens,
          j,
          "expected field name, found: \{token_name(tok)}",
        )
    }
    let (field, next_expr) = if j + 1 < tokens.length() &&
      token_kind(tokens, j + 1) == LParenTok {
      let (value_expr, next_expr) = parse_named_lambda_sugar(
        tokens,
        name,
        j + 1,
        j,
      )
      (SRecordField(name, value_expr), next_expr)
    } else if j + 1 < tokens.length() && token_kind(tokens, j + 1) == AssignTok {
      let (value_expr, next_expr) = parse_expr(tokens, j + 2)
      (SRecordField(name, value_expr), next_expr)
    } else {
      (SRecordShorthand(name), j + 1)
    }
    fields.push(field)
    if next_expr >= tokens.length() {
      syntax_error_eof(tokens, "unexpected end in record")
    }
    if token_kind(tokens, next_expr) == SemicolonTok {
      continue next_expr + 1, _pos + 1
    }
    if token_kind(tokens, next_expr) == RBraceTok {
      break (
        located_expr(tokens, i - 1, next_expr + 1, SRecord(fields)),
        next_expr + 1,
      )
    }
    syntax_error_at(
      tokens,
      next_expr,
      "unexpected token in record: \{token_name(token_kind(tokens, next_expr))}",
    )
  }
}

///|
fn parse_list_literal(
  tokens : Array[SpannedToken],
  i : Int,
) -> (SurfaceExpr, Int) raise {
  if i < tokens.length() && token_kind(tokens, i) == RBracketTok {
    return (located_expr(tokens, i - 1, i + 1, SList([])), i + 1)
  }
  let items = []
  for j = i, _pos = 0 {
    let (item, next_expr) = parse_expr(tokens, j)
    items.push(item)
    if next_expr >= tokens.length() {
      syntax_error_eof(tokens, "unexpected end in list")
    }
    if token_kind(tokens, next_expr) == SemicolonTok {
      continue next_expr + 1, _pos + 1
    }
    if token_kind(tokens, next_expr) == RBracketTok {
      break (
        located_expr(tokens, i - 1, next_expr + 1, SList(items)),
        next_expr + 1,
      )
    }
    syntax_error_at(
      tokens,
      next_expr,
      "unexpected token in list: \{token_name(token_kind(tokens, next_expr))}",
    )
  }
}

///|
fn parse_pattern(
  tokens : Array[SpannedToken],
  i : Int,
) -> (SurfacePattern, Int) raise {
  let (pattern, j) = parse_pattern_atom(tokens, i)
  parse_pattern_or_tail(pattern, tokens, j)
}

///|
fn parse_pattern_or_tail(
  left : SurfacePattern,
  tokens : Array[SpannedToken],
  i : Int,
) -> (SurfacePattern, Int) raise {
  if i < tokens.length() && token_kind(tokens, i) == PipeTok {
    let (right, j) = parse_pattern_atom(tokens, i + 1)
    let combined = match left {
      SPOr(patterns) => SPOr(patterns + [right])
      _ => SPOr([left, right])
    }
    ensure_or_pattern_bindings(combined, tokens, i)
    parse_pattern_or_tail(combined, tokens, j)
  } else {
    (left, i)
  }
}

///|
fn parse_pattern_atom(
  tokens : Array[SpannedToken],
  i : Int,
) -> (SurfacePattern, Int) raise {
  if i >= tokens.length() {
    syntax_error_eof(tokens, "unexpected end in pattern")
  }
  match token_kind(tokens, i) {
    IdentTok(name) => (SPBind(name), i + 1)
    IntTok(value) => (SPInt(value), i + 1)
    StrTok(value) => (SPString(value), i + 1)
    TrueTok => (SPBool(true), i + 1)
    FalseTok => (SPBool(false), i + 1)
    NilTok => (SPNil, i + 1)
    HashTok => parse_variant_pattern(tokens, i + 1)
    LBracketTok => parse_list_pattern(tokens, i + 1)
    LBraceTok => parse_match_record_pattern(tokens, i + 1)
    tok =>
      syntax_error_at(
        tokens,
        i,
        "unexpected token in pattern: \{token_name(tok)}",
      )
  }
}

///|
fn ensure_or_pattern_bindings(
  pattern : SurfacePattern,
  tokens : Array[SpannedToken],
  error_i : Int,
) -> Unit raise {
  match pattern {
    SPOr(patterns) =>
      if patterns.length() > 0 {
        let expected = pattern_binding_names(patterns[0])
        ensure_or_pattern_bindings_all(patterns, expected, 1, tokens, error_i)
      }
    _ => ()
  }
}

///|
fn ensure_or_pattern_bindings_all(
  patterns : Array[SurfacePattern],
  expected : Array[String],
  i : Int,
  tokens : Array[SpannedToken],
  error_i : Int,
) -> Unit raise {
  if i >= patterns.length() {
    return
  }
  let actual = pattern_binding_names(patterns[i])
  if !same_binding_names(expected, actual) {
    syntax_error_at(
      tokens, error_i, "all alternatives in an or-pattern must bind the same names",
    )
  }
  ensure_or_pattern_bindings_all(patterns, expected, i + 1, tokens, error_i)
}

///|
fn pattern_binding_names(pattern : SurfacePattern) -> Array[String] {
  match pattern {
    SPBind(name) => if name == "_" { [] } else { [name] }
    SPInt(_) => []
    SPBool(_) => []
    SPString(_) => []
    SPNil => []
    SPOr(patterns) =>
      if patterns.length() == 0 {
        []
      } else {
        pattern_binding_names(patterns[0])
      }
    SPVariant(_, inner) => pattern_binding_names(inner)
    SPList(items) =>
      items.fold(init=[], (acc, item) => acc + pattern_binding_names(item))
    SPListRest(prefix, rest_name, suffix) => {
      let with_prefix = prefix.fold(init=[], (acc, item) => {
        acc + pattern_binding_names(item)
      })
      let with_rest = if rest_name == "_" {
        with_prefix
      } else {
        with_prefix + [rest_name]
      }
      suffix.fold(init=with_rest, (acc, item) => {
        acc + pattern_binding_names(item)
      })
    }
    SPRecord(fields) =>
      fields.fold(init=[], (acc, field) => {
        match field {
          SPRecordField(_, field_pattern) =>
            acc + pattern_binding_names(field_pattern)
          SPRecordShorthand(name) =>
            if name == "_" {
              acc
            } else {
              acc + [name]
            }
        }
      })
  }
}

///|
fn same_binding_names(left : Array[String], right : Array[String]) -> Bool {
  if left.length() != right.length() {
    return false
  }
  same_binding_names_from(left, right, 0)
}

///|
fn same_binding_names_from(
  left : Array[String],
  right : Array[String],
  i : Int,
) -> Bool {
  if i >= left.length() {
    return true
  }
  if !array_contains_string(right, left[i]) {
    return false
  }
  same_binding_names_from(left, right, i + 1)
}

///|
fn array_contains_string(items : Array[String], target : String) -> Bool {
  array_contains_string_from(items, target, 0)
}

///|
fn array_contains_string_from(
  items : Array[String],
  target : String,
  i : Int,
) -> Bool {
  if i >= items.length() {
    return false
  }
  if items[i] == target {
    return true
  }
  array_contains_string_from(items, target, i + 1)
}

///|
fn parse_variant_pattern(
  tokens : Array[SpannedToken],
  i : Int,
) -> (SurfacePattern, Int) raise {
  if i >= tokens.length() {
    syntax_error_eof(tokens, "expected variant name after '#'")
  }
  let tag = match token_kind(tokens, i) {
    IdentTok(name) => name
    tok =>
      syntax_error_at(
        tokens,
        i,
        "expected variant name, found: \{token_name(tok)}",
      )
  }
  if i + 1 >= tokens.length() || token_kind(tokens, i + 1) != LParenTok {
    syntax_error_at(tokens, i + 1, "expected '(' after variant name")
  }
  let (inner, j) = parse_pattern(tokens, i + 2)
  if j >= tokens.length() || token_kind(tokens, j) != RParenTok {
    syntax_error_at(tokens, j, "expected ')' after variant pattern")
  }
  (SPVariant(tag, inner), j + 1)
}

///|
fn parse_list_pattern(
  tokens : Array[SpannedToken],
  i : Int,
) -> (SurfacePattern, Int) raise {
  if i < tokens.length() && token_kind(tokens, i) == RBracketTok {
    return (SPList([]), i + 1)
  }
  let prefix = []
  for j = i, _pos = 0 {
    if j >= tokens.length() {
      syntax_error_eof(tokens, "unexpected end in list pattern")
    }
    if token_kind(tokens, j) == DotDotTok {
      return parse_list_pattern_rest(tokens, j + 1, prefix)
    }
    let (pattern, next_pattern) = parse_pattern(tokens, j)
    prefix.push(pattern)
    if next_pattern >= tokens.length() {
      syntax_error_eof(tokens, "unexpected end in list pattern")
    }
    if token_kind(tokens, next_pattern) == SemicolonTok {
      continue next_pattern + 1, _pos + 1
    }
    if token_kind(tokens, next_pattern) == RBracketTok {
      break (SPList(prefix), next_pattern + 1)
    }
    syntax_error_at(
      tokens,
      next_pattern,
      "unexpected token in list pattern: \{token_name(token_kind(tokens, next_pattern))}",
    )
  }
}

///|
fn parse_list_pattern_rest(
  tokens : Array[SpannedToken],
  i : Int,
  prefix : Array[SurfacePattern],
) -> (SurfacePattern, Int) raise {
  if i >= tokens.length() {
    syntax_error_eof(
      tokens, "expected binding name, ';' or ']' after '..' in list pattern",
    )
  }
  let (rest_name, next_i) = match token_kind(tokens, i) {
    IdentTok(name) => (name, i + 1)
    SemicolonTok => ("_", i)
    RBracketTok => ("_", i)
    tok =>
      syntax_error_at(
        tokens,
        i,
        "expected binding name, ';' or ']' after '..', found: \{token_name(tok)}",
      )
  }
  if next_i >= tokens.length() {
    syntax_error_eof(tokens, "unexpected end in list pattern")
  }
  if token_kind(tokens, next_i) == RBracketTok {
    return (SPListRest(prefix, rest_name, []), next_i + 1)
  }
  if token_kind(tokens, next_i) != SemicolonTok {
    syntax_error_at(
      tokens,
      next_i,
      "expected ';' or ']' after list rest binding, found: \{token_name(token_kind(tokens, next_i))}",
    )
  }
  let suffix = []
  for j = next_i + 1, _pos = 0 {
    if j >= tokens.length() {
      syntax_error_eof(tokens, "unexpected end in list pattern")
    }
    if token_kind(tokens, j) == DotDotTok {
      syntax_error_at(
        tokens, j, "list pattern can contain at most one '..' binding",
      )
    }
    let (pattern, next_pattern) = parse_pattern(tokens, j)
    suffix.push(pattern)
    if next_pattern >= tokens.length() {
      syntax_error_eof(tokens, "unexpected end in list pattern")
    }
    if token_kind(tokens, next_pattern) == SemicolonTok {
      continue next_pattern + 1, _pos + 1
    }
    if token_kind(tokens, next_pattern) == RBracketTok {
      break (SPListRest(prefix, rest_name, suffix), next_pattern + 1)
    }
    syntax_error_at(
      tokens,
      next_pattern,
      "unexpected token in list pattern: \{token_name(token_kind(tokens, next_pattern))}",
    )
  }
}

///|
fn parse_match_record_pattern(
  tokens : Array[SpannedToken],
  i : Int,
) -> (SurfacePattern, Int) raise {
  if i < tokens.length() && token_kind(tokens, i) == RBraceTok {
    return (SPRecord([]), i + 1)
  }
  let fields = []
  for j = i, _pos = 0 {
    if j >= tokens.length() {
      syntax_error_eof(tokens, "unexpected end in record pattern")
    }
    let field_name = match token_kind(tokens, j) {
      IdentTok(name) => name
      tok =>
        syntax_error_at(
          tokens,
          j,
          "expected field name, found: \{token_name(tok)}",
        )
    }
    let (field, next) = if j + 1 < tokens.length() &&
      token_kind(tokens, j + 1) == AssignTok {
      let (pattern, k) = parse_pattern(tokens, j + 2)
      (SPRecordField(field_name, pattern), k)
    } else {
      (SPRecordShorthand(field_name), j + 1)
    }
    fields.push(field)
    if next >= tokens.length() {
      syntax_error_eof(tokens, "unexpected end in record pattern")
    }
    if token_kind(tokens, next) == SemicolonTok {
      continue next + 1, _pos + 1
    }
    if token_kind(tokens, next) == RBraceTok {
      break (SPRecord(fields), next + 1)
    }
    syntax_error_at(
      tokens,
      next,
      "unexpected token in record pattern: \{token_name(token_kind(tokens, next))}",
    )
  }
}
