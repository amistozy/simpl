///|
pub type SourcePos = (Int, Int, Int)

///|
pub type SourceSpan = (SourcePos, SourcePos)

///|
type SpannedToken = (Token, SourceSpan)

///|
/// Parser error type
pub suberror ParseError {
  SyntaxError(String)
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
  InTok
  IfTok
  ThenTok
  ElseTok
  FnTok
  NotTok
  RefTok
  MatchTok
  AndWordTok
  OrWordTok
  PlusTok
  MinusTok
  StarTok
  SlashTok
  EqEqTok
  BangEqTok
  LtTok
  LeTok
  GtTok
  GeTok
  AndAndTok
  OrOrTok
  AssignTok
  ArrowTok
  BangTok
  ColonEqTok
  ColonTok
  DotDotTok
  PipeTok
  DotTok
  HashTok
  SemiTok
  LBraceTok
  RBraceTok
  LBracketTok
  RBracketTok
  LParenTok
  RParenTok
  CommaTok
  EndTok
} derive(Eq)

///|
pub fn parse(source : String) -> Expr raise {
  let tokens = lex(source)
  let (expr, i) = parse_expr(tokens, 0)
  if i >= tokens.length() {
    raise SyntaxErrorAt("unexpected end", eof_span(tokens))
  }
  if token_kind(tokens, i) == EndTok {
    expr
  } else {
    raise SyntaxErrorAt(
      "unexpected token after expression: " + token_name(token_kind(tokens, i)),
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
  eval(parse(source))
}

///|
pub fn format_parse_error(error : ParseError) -> String {
  match error {
    SyntaxError(message) => message
    SyntaxErrorAt(message, span) => message + " at " + format_source_span(span)
  }
}

///|
pub fn parse_error_text(source : String) -> String? {
  try parse(source) catch {
    SyntaxError(message) => Some(message)
    SyntaxErrorAt(message, span) =>
      Some(message + " at " + format_source_span(span))
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
      let end = scan_string_end(source, i + 1)
      let content = source[i + 1:end].to_string()
      let span = make_span(source, i, end + 1, line, column)
      acc.push((StrTok(content), span))
      let (_, end_pos) = span
      let (_, next_line, next_column) = end_pos
      lex_loop(source, end + 1, next_line, next_column, acc)
    }
    '(' => push_single_char_token(source, i, line, column, LParenTok, acc)
    ')' => push_single_char_token(source, i, line, column, RParenTok, acc)
    ',' => push_single_char_token(source, i, line, column, CommaTok, acc)
    ';' => push_single_char_token(source, i, line, column, SemiTok, acc)
    '+' => push_single_char_token(source, i, line, column, PlusTok, acc)
    '-' => push_single_char_token(source, i, line, column, MinusTok, acc)
    '*' => push_single_char_token(source, i, line, column, StarTok, acc)
    '/' => push_single_char_token(source, i, line, column, SlashTok, acc)
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
        } else if n == '>' {
          push_multi_char_token(source, i, i + 2, line, column, ArrowTok, acc)
        } else {
          push_single_char_token(source, i, line, column, AssignTok, acc)
        }
      } else {
        push_single_char_token(source, i, line, column, AssignTok, acc)
      }
    '!' =>
      if i + 1 < source.length() &&
        source.unsafe_get(i + 1).unsafe_to_char() == '=' {
        push_multi_char_token(source, i, i + 2, line, column, BangEqTok, acc)
      } else {
        push_single_char_token(source, i, line, column, BangTok, acc)
      }
    ':' =>
      if i + 1 < source.length() &&
        source.unsafe_get(i + 1).unsafe_to_char() == '=' {
        push_multi_char_token(source, i, i + 2, line, column, ColonEqTok, acc)
      } else {
        push_single_char_token(source, i, line, column, ColonTok, acc)
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
        push_multi_char_token(source, i, i + 2, line, column, OrOrTok, acc)
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
        push_multi_char_token(source, i, i + 2, line, column, AndAndTok, acc)
      } else {
        raise SyntaxErrorAt(
          "unexpected token '&'",
          make_span(source, i, i + 1, line, column),
        )
      }
    _ =>
      raise SyntaxErrorAt(
        "unexpected character: " + c.to_string(),
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
  expr : Expr,
) -> Expr {
  Located(expr_span(tokens, start_i, end_i), expr)
}

///|
fn located_expr_from_left(
  left : Expr,
  tokens : Array[SpannedToken],
  end_i : Int,
  expr : Expr,
) -> Expr {
  let (start_pos, _) = expr_known_span(left)
  let (_, end_pos) = token_span_at(tokens, end_i - 1)
  Located((start_pos, end_pos), expr)
}

///|
fn expr_known_span(expr : Expr) -> SourceSpan {
  match expr {
    Located(span, _) => span
    _ => ((0, 1, 1), (0, 1, 1))
  }
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
fn scan_string_end(source : String, i : Int) -> Int raise {
  if i >= source.length() {
    raise SyntaxError("unterminated string literal")
  }
  if source.unsafe_get(i).unsafe_to_char() == '"' {
    i
  } else {
    scan_string_end(source, i + 1)
  }
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
    "in" => InTok
    "if" => IfTok
    "then" => ThenTok
    "else" => ElseTok
    "fn" => FnTok
    "not" => NotTok
    "ref" => RefTok
    "match" => MatchTok
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
    IdentTok(name) => "identifier(" + name + ")"
    TrueTok => "true"
    FalseTok => "false"
    NilTok => "nil"
    LetTok => "let"
    RecTok => "rec"
    InTok => "in"
    IfTok => "if"
    ThenTok => "then"
    ElseTok => "else"
    FnTok => "fn"
    NotTok => "not"
    RefTok => "ref"
    MatchTok => "match"
    AndWordTok => "and"
    OrWordTok => "or"
    PlusTok => "+"
    MinusTok => "-"
    StarTok => "*"
    SlashTok => "/"
    EqEqTok => "=="
    BangEqTok => "!="
    LtTok => "<"
    LeTok => "<="
    GtTok => ">"
    GeTok => ">="
    AndAndTok => "&&"
    OrOrTok => "||"
    AssignTok => "="
    ArrowTok => "=>"
    BangTok => "!"
    ColonEqTok => ":="
    ColonTok => ":"
    DotDotTok => ".."
    PipeTok => "|"
    DotTok => "."
    HashTok => "#"
    SemiTok => ";"
    LBraceTok => "{"
    RBraceTok => "}"
    LBracketTok => "["
    RBracketTok => "]"
    LParenTok => "("
    RParenTok => ")"
    CommaTok => ","
    EndTok => "<eof>"
  }
}

///|
fn parse_expr(tokens : Array[SpannedToken], i : Int) -> (Expr, Int) raise {
  parse_seq_expr(tokens, i)
}

///|
fn parse_seq_expr(tokens : Array[SpannedToken], i : Int) -> (Expr, Int) raise {
  let (left, j) = parse_assign_expr(tokens, i)
  if j < tokens.length() && token_kind(tokens, j) == SemiTok {
    let (right, k) = parse_seq_expr(tokens, j + 1)
    (located_expr(tokens, i, k, Let(PBind("_"), left, right)), k)
  } else {
    (left, j)
  }
}

///|
fn parse_assign_expr(
  tokens : Array[SpannedToken],
  i : Int,
) -> (Expr, Int) raise {
  let (left, j) = parse_let_expr(tokens, i)
  if j < tokens.length() && token_kind(tokens, j) == ColonEqTok {
    let (right, k) = parse_assign_expr(tokens, j + 1)
    (located_expr(tokens, i, k, RefSet(left, right)), k)
  } else {
    (left, j)
  }
}

///|
fn parse_let_expr(tokens : Array[SpannedToken], i : Int) -> (Expr, Int) raise {
  if i >= tokens.length() {
    raise SyntaxError("unexpected end")
  }
  if token_kind(tokens, i) == LetTok {
    if i + 1 < tokens.length() && token_kind(tokens, i + 1) == RecTok {
      parse_let_rec_expr(tokens, i + 2)
    } else {
      parse_plain_let_expr(tokens, i + 1)
    }
  } else {
    parse_if_expr(tokens, i)
  }
}

///|
fn parse_plain_let_expr(
  tokens : Array[SpannedToken],
  i : Int,
) -> (Expr, Int) raise {
  if i >= tokens.length() {
    raise SyntaxError("expected pattern after 'let'")
  }
  match token_kind(tokens, i) {
    IdentTok(name) =>
      if i + 1 < tokens.length() && token_kind(tokens, i + 1) == LParenTok {
        let (params, j) = parse_params(tokens, i + 2)
        if j >= tokens.length() || token_kind(tokens, j) != AssignTok {
          raise SyntaxError("expected '=' after let function params")
        }
        let (func_body, k) = parse_expr(tokens, j + 1)
        if k >= tokens.length() || token_kind(tokens, k) != InTok {
          raise SyntaxError("expected 'in' after let function binding")
        }
        let (body, m) = parse_expr(tokens, k + 1)
        (
          located_expr(
            tokens,
            i,
            m,
            Let(PBind(name), Lambda(params, func_body), body),
          ),
          m,
        )
      } else {
        let (pattern, j) = parse_pattern(tokens, i)
        if j >= tokens.length() || token_kind(tokens, j) != AssignTok {
          raise SyntaxError("expected '=' after let pattern")
        }
        let (value_expr, k) = parse_expr(tokens, j + 1)
        if k >= tokens.length() || token_kind(tokens, k) != InTok {
          raise SyntaxError("expected 'in' after let binding")
        }
        let (body, m) = parse_expr(tokens, k + 1)
        (located_expr(tokens, i, m, Let(pattern, value_expr, body)), m)
      }
    _ => {
      let (pattern, j) = parse_pattern(tokens, i)
      if j >= tokens.length() || token_kind(tokens, j) != AssignTok {
        raise SyntaxError("expected '=' after let pattern")
      }
      let (value_expr, k) = parse_expr(tokens, j + 1)
      if k >= tokens.length() || token_kind(tokens, k) != InTok {
        raise SyntaxError("expected 'in' after let binding")
      }
      let (body, m) = parse_expr(tokens, k + 1)
      (located_expr(tokens, i, m, Let(pattern, value_expr, body)), m)
    }
  }
}

///|
fn parse_let_rec_expr(
  tokens : Array[SpannedToken],
  i : Int,
) -> (Expr, Int) raise {
  if i >= tokens.length() {
    raise SyntaxError("expected function name after 'let rec'")
  }
  match token_kind(tokens, i) {
    IdentTok(name) => {
      if i + 1 >= tokens.length() || token_kind(tokens, i + 1) != LParenTok {
        raise SyntaxError("expected '(...)' after let rec function name")
      }
      let (params, j) = parse_params(tokens, i + 2)
      if j >= tokens.length() || token_kind(tokens, j) != AssignTok {
        raise SyntaxError("expected '=' after let rec params")
      }
      let (func_body, k) = parse_expr(tokens, j + 1)
      if k >= tokens.length() || token_kind(tokens, k) != InTok {
        raise SyntaxError("expected 'in' after let rec binding")
      }
      let (body, m) = parse_expr(tokens, k + 1)
      (located_expr(tokens, i, m, LetRec(name, params, func_body, body)), m)
    }
    _ => raise SyntaxError("expected function name after 'let rec'")
  }
}

///|
fn parse_if_expr(tokens : Array[SpannedToken], i : Int) -> (Expr, Int) raise {
  if i < tokens.length() && token_kind(tokens, i) == IfTok {
    let (cond, j) = parse_expr(tokens, i + 1)
    if j >= tokens.length() || token_kind(tokens, j) != ThenTok {
      raise SyntaxError("expected 'then' in if expression")
    }
    let (then_expr, k) = parse_expr(tokens, j + 1)
    if k >= tokens.length() || token_kind(tokens, k) != ElseTok {
      raise SyntaxError("expected 'else' in if expression")
    }
    let (else_expr, m) = parse_expr(tokens, k + 1)
    (located_expr(tokens, i, m, If(cond, then_expr, else_expr)), m)
  } else {
    parse_match_expr(tokens, i)
  }
}

///|
fn parse_match_expr(tokens : Array[SpannedToken], i : Int) -> (Expr, Int) raise {
  if i < tokens.length() && token_kind(tokens, i) == MatchTok {
    let (value_expr, j) = parse_expr(tokens, i + 1)
    if j >= tokens.length() || token_kind(tokens, j) != LBraceTok {
      raise SyntaxError("expected '{' after match expression")
    }
    let (cases, k) = parse_match_cases(tokens, j + 1)
    (located_expr(tokens, i, k, Match(value_expr, cases)), k)
  } else {
    parse_lambda_expr(tokens, i)
  }
}

///|
fn parse_lambda_expr(
  tokens : Array[SpannedToken],
  i : Int,
) -> (Expr, Int) raise {
  if i < tokens.length() && token_kind(tokens, i) == FnTok {
    if i + 1 >= tokens.length() || token_kind(tokens, i + 1) != LParenTok {
      raise SyntaxError("expected '(' after 'fn'")
    }
    let (params, j) = parse_params(tokens, i + 2)
    if j >= tokens.length() || token_kind(tokens, j) != ArrowTok {
      raise SyntaxError("expected '=>' after lambda params")
    }
    let (body, k) = parse_expr(tokens, j + 1)
    (located_expr(tokens, i, k, Lambda(params, body)), k)
  } else {
    parse_or_expr(tokens, i)
  }
}

///|
fn parse_params(
  tokens : Array[SpannedToken],
  i : Int,
) -> (Array[MatchPattern], Int) raise {
  if i >= tokens.length() {
    raise SyntaxError("unexpected end in params")
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
) -> (Array[MatchPattern], Int) raise {
  let params = []
  for j = i, _pos = 0 {
    let (pattern, next) = parse_pattern(tokens, j)
    params.push(pattern)
    if next >= tokens.length() {
      raise SyntaxError("unexpected end in params")
    }
    if token_kind(tokens, next) == CommaTok {
      continue next + 1, _pos + 1
    }
    if token_kind(tokens, next) == RParenTok {
      break (params, next + 1)
    }
    raise SyntaxError(
      "unexpected token in params: " + token_name(token_kind(tokens, next)),
    )
  }
}

///|
fn parse_or_expr(tokens : Array[SpannedToken], i : Int) -> (Expr, Int) raise {
  let (left, j) = parse_and_expr(tokens, i)
  parse_or_tail(left, tokens, j)
}

///|
fn parse_or_tail(
  left : Expr,
  tokens : Array[SpannedToken],
  i : Int,
) -> (Expr, Int) raise {
  if i < tokens.length() &&
    (token_kind(tokens, i) == OrOrTok || token_kind(tokens, i) == OrWordTok) {
    let (right, j) = parse_and_expr(tokens, i + 1)
    parse_or_tail(
      located_expr_from_left(left, tokens, j, Binary(Or, left, right)),
      tokens,
      j,
    )
  } else {
    (left, i)
  }
}

///|
fn parse_and_expr(tokens : Array[SpannedToken], i : Int) -> (Expr, Int) raise {
  let (left, j) = parse_eq_expr(tokens, i)
  parse_and_tail(left, tokens, j)
}

///|
fn parse_and_tail(
  left : Expr,
  tokens : Array[SpannedToken],
  i : Int,
) -> (Expr, Int) raise {
  if i < tokens.length() &&
    (token_kind(tokens, i) == AndAndTok || token_kind(tokens, i) == AndWordTok) {
    let (right, j) = parse_eq_expr(tokens, i + 1)
    parse_and_tail(
      located_expr_from_left(left, tokens, j, Binary(And, left, right)),
      tokens,
      j,
    )
  } else {
    (left, i)
  }
}

///|
fn parse_eq_expr(tokens : Array[SpannedToken], i : Int) -> (Expr, Int) raise {
  let (left, j) = parse_cmp_expr(tokens, i)
  parse_eq_tail(left, tokens, j)
}

///|
fn parse_eq_tail(
  left : Expr,
  tokens : Array[SpannedToken],
  i : Int,
) -> (Expr, Int) raise {
  if i < tokens.length() && token_kind(tokens, i) == EqEqTok {
    let (right, j) = parse_cmp_expr(tokens, i + 1)
    parse_eq_tail(
      located_expr_from_left(left, tokens, j, Binary(Eq, left, right)),
      tokens,
      j,
    )
  } else if i < tokens.length() && token_kind(tokens, i) == BangEqTok {
    let (right, j) = parse_cmp_expr(tokens, i + 1)
    parse_eq_tail(
      located_expr_from_left(left, tokens, j, Binary(Ne, left, right)),
      tokens,
      j,
    )
  } else {
    (left, i)
  }
}

///|
fn parse_cmp_expr(tokens : Array[SpannedToken], i : Int) -> (Expr, Int) raise {
  let (left, j) = parse_add_expr(tokens, i)
  parse_cmp_tail(left, tokens, j)
}

///|
fn parse_cmp_tail(
  left : Expr,
  tokens : Array[SpannedToken],
  i : Int,
) -> (Expr, Int) raise {
  if i < tokens.length() && token_kind(tokens, i) == LtTok {
    let (right, j) = parse_add_expr(tokens, i + 1)
    parse_cmp_tail(
      located_expr_from_left(left, tokens, j, Binary(Lt, left, right)),
      tokens,
      j,
    )
  } else if i < tokens.length() && token_kind(tokens, i) == LeTok {
    let (right, j) = parse_add_expr(tokens, i + 1)
    parse_cmp_tail(
      located_expr_from_left(left, tokens, j, Binary(Le, left, right)),
      tokens,
      j,
    )
  } else if i < tokens.length() && token_kind(tokens, i) == GtTok {
    let (right, j) = parse_add_expr(tokens, i + 1)
    parse_cmp_tail(
      located_expr_from_left(left, tokens, j, Binary(Gt, left, right)),
      tokens,
      j,
    )
  } else if i < tokens.length() && token_kind(tokens, i) == GeTok {
    let (right, j) = parse_add_expr(tokens, i + 1)
    parse_cmp_tail(
      located_expr_from_left(left, tokens, j, Binary(Ge, left, right)),
      tokens,
      j,
    )
  } else {
    (left, i)
  }
}

///|
fn parse_add_expr(tokens : Array[SpannedToken], i : Int) -> (Expr, Int) raise {
  let (left, j) = parse_mul_expr(tokens, i)
  parse_add_tail(left, tokens, j)
}

///|
fn parse_add_tail(
  left : Expr,
  tokens : Array[SpannedToken],
  i : Int,
) -> (Expr, Int) raise {
  if i < tokens.length() && token_kind(tokens, i) == PlusTok {
    let (right, j) = parse_mul_expr(tokens, i + 1)
    parse_add_tail(
      located_expr_from_left(left, tokens, j, Binary(Add, left, right)),
      tokens,
      j,
    )
  } else if i < tokens.length() && token_kind(tokens, i) == MinusTok {
    let (right, j) = parse_mul_expr(tokens, i + 1)
    parse_add_tail(
      located_expr_from_left(left, tokens, j, Binary(Sub, left, right)),
      tokens,
      j,
    )
  } else {
    (left, i)
  }
}

///|
fn parse_mul_expr(tokens : Array[SpannedToken], i : Int) -> (Expr, Int) raise {
  let (left, j) = parse_unary_expr(tokens, i)
  parse_mul_tail(left, tokens, j)
}

///|
fn parse_mul_tail(
  left : Expr,
  tokens : Array[SpannedToken],
  i : Int,
) -> (Expr, Int) raise {
  if i < tokens.length() && token_kind(tokens, i) == StarTok {
    let (right, j) = parse_unary_expr(tokens, i + 1)
    parse_mul_tail(
      located_expr_from_left(left, tokens, j, Binary(Mul, left, right)),
      tokens,
      j,
    )
  } else if i < tokens.length() && token_kind(tokens, i) == SlashTok {
    let (right, j) = parse_unary_expr(tokens, i + 1)
    parse_mul_tail(
      located_expr_from_left(left, tokens, j, Binary(Div, left, right)),
      tokens,
      j,
    )
  } else {
    (left, i)
  }
}

///|
fn parse_unary_expr(tokens : Array[SpannedToken], i : Int) -> (Expr, Int) raise {
  if i < tokens.length() && token_kind(tokens, i) == RefTok {
    let (expr, j) = parse_unary_expr(tokens, i + 1)
    (located_expr(tokens, i, j, RefNew(expr)), j)
  } else if i < tokens.length() && token_kind(tokens, i) == BangTok {
    let (expr, j) = parse_unary_expr(tokens, i + 1)
    (located_expr(tokens, i, j, RefGet(expr)), j)
  } else if i < tokens.length() && token_kind(tokens, i) == MinusTok {
    let (expr, j) = parse_unary_expr(tokens, i + 1)
    (located_expr(tokens, i, j, Unary(Neg, expr)), j)
  } else if i < tokens.length() && token_kind(tokens, i) == NotTok {
    let (expr, j) = parse_unary_expr(tokens, i + 1)
    (located_expr(tokens, i, j, Unary(Not, expr)), j)
  } else {
    parse_postfix_expr(tokens, i)
  }
}

///|
fn parse_postfix_expr(
  tokens : Array[SpannedToken],
  i : Int,
) -> (Expr, Int) raise {
  let (expr, j) = parse_primary_expr(tokens, i)
  parse_postfix_tail(expr, tokens, j)
}

///|
fn parse_postfix_tail(
  expr : Expr,
  tokens : Array[SpannedToken],
  i : Int,
) -> (Expr, Int) raise {
  if i < tokens.length() && token_kind(tokens, i) == LParenTok {
    let (args, j) = parse_args(tokens, i + 1)
    parse_postfix_tail(
      located_expr_from_left(expr, tokens, j, Call(expr, args)),
      tokens,
      j,
    )
  } else if i < tokens.length() && token_kind(tokens, i) == DotTok {
    if i + 1 >= tokens.length() {
      raise SyntaxError("expected field name after '.'")
    }
    match token_kind(tokens, i + 1) {
      IdentTok(name) =>
        parse_postfix_tail(
          located_expr_from_left(expr, tokens, i + 2, Field(expr, name)),
          tokens,
          i + 2,
        )
      tok => raise SyntaxError("expected field name, found: " + token_name(tok))
    }
  } else {
    (expr, i)
  }
}

///|
fn parse_args(
  tokens : Array[SpannedToken],
  i : Int,
) -> (Array[Expr], Int) raise {
  if i >= tokens.length() {
    raise SyntaxError("unexpected end in args")
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
) -> (Array[Expr], Int) raise {
  let args = []
  for j = i, _pos = 0 {
    let (arg, next_expr) = parse_expr(tokens, j)
    args.push(arg)
    if next_expr >= tokens.length() {
      raise SyntaxError("unexpected end in args")
    }
    if token_kind(tokens, next_expr) == CommaTok {
      continue next_expr + 1, _pos + 1
    }
    if token_kind(tokens, next_expr) == RParenTok {
      break (args, next_expr + 1)
    }
    raise SyntaxError(
      "unexpected token in args: " + token_name(token_kind(tokens, next_expr)),
    )
  }
}

///|
fn parse_primary_expr(
  tokens : Array[SpannedToken],
  i : Int,
) -> (Expr, Int) raise {
  if i >= tokens.length() {
    raise SyntaxError("unexpected end")
  }
  match token_kind(tokens, i) {
    IntTok(v) => (located_expr(tokens, i, i + 1, IntLit(v)), i + 1)
    StrTok(v) => (located_expr(tokens, i, i + 1, StringLit(v)), i + 1)
    TrueTok => (located_expr(tokens, i, i + 1, BoolLit(true)), i + 1)
    FalseTok => (located_expr(tokens, i, i + 1, BoolLit(false)), i + 1)
    NilTok => (located_expr(tokens, i, i + 1, NilLit), i + 1)
    IdentTok(name) => (located_expr(tokens, i, i + 1, Var(name)), i + 1)
    HashTok => parse_variant_literal(tokens, i + 1)
    LBraceTok => parse_record_literal(tokens, i + 1)
    LBracketTok => parse_list_literal(tokens, i + 1)
    LParenTok => {
      let (expr, j) = parse_expr(tokens, i + 1)
      if j < tokens.length() && token_kind(tokens, j) == RParenTok {
        (located_expr(tokens, i, j + 1, expr), j + 1)
      } else if j < tokens.length() {
        raise SyntaxError(
          "expected ')', found: " + token_name(token_kind(tokens, j)),
        )
      } else {
        raise SyntaxError("expected ')' but found end")
      }
    }
    tok => raise SyntaxError("unexpected token: " + token_name(tok))
  }
}

///|
fn parse_variant_literal(
  tokens : Array[SpannedToken],
  i : Int,
) -> (Expr, Int) raise {
  if i >= tokens.length() {
    raise SyntaxError("expected variant name after '#'")
  }
  match token_kind(tokens, i) {
    IdentTok(tag) => {
      if i + 1 >= tokens.length() || token_kind(tokens, i + 1) != LParenTok {
        raise SyntaxError("expected '(' after variant tag")
      }
      let (value_expr, j) = parse_expr(tokens, i + 2)
      if j >= tokens.length() || token_kind(tokens, j) != RParenTok {
        raise SyntaxError("expected ')' after variant payload")
      }
      (located_expr(tokens, i - 1, j + 1, Variant(tag, value_expr)), j + 1)
    }
    tok => raise SyntaxError("expected variant name, found: " + token_name(tok))
  }
}

///|
fn parse_record_literal(
  tokens : Array[SpannedToken],
  i : Int,
) -> (Expr, Int) raise {
  if i < tokens.length() && token_kind(tokens, i) == RBraceTok {
    return (located_expr(tokens, i - 1, i + 1, Record([])), i + 1)
  }
  let fields = []
  for j = i, _pos = 0 {
    if j >= tokens.length() {
      raise SyntaxError("unexpected end in record")
    }
    let name = match token_kind(tokens, j) {
      IdentTok(field_name) => field_name
      tok => raise SyntaxError("expected field name, found: " + token_name(tok))
    }
    let (value_expr, next_expr) = if j + 1 < tokens.length() &&
      token_kind(tokens, j + 1) == ColonTok {
      parse_expr(tokens, j + 2)
    } else {
      (Var(name), j + 1)
    }
    fields.push((name, value_expr))
    if next_expr >= tokens.length() {
      raise SyntaxError("unexpected end in record")
    }
    if token_kind(tokens, next_expr) == CommaTok {
      continue next_expr + 1, _pos + 1
    }
    if token_kind(tokens, next_expr) == RBraceTok {
      break (
        located_expr(tokens, i - 1, next_expr + 1, Record(fields)),
        next_expr + 1,
      )
    }
    raise SyntaxError(
      "unexpected token in record: " + token_name(token_kind(tokens, next_expr)),
    )
  }
}

///|
fn parse_list_literal(
  tokens : Array[SpannedToken],
  i : Int,
) -> (Expr, Int) raise {
  if i < tokens.length() && token_kind(tokens, i) == RBracketTok {
    return (located_expr(tokens, i - 1, i + 1, List([])), i + 1)
  }
  let items = []
  for j = i, _pos = 0 {
    let (item, next_expr) = parse_expr(tokens, j)
    items.push(item)
    if next_expr >= tokens.length() {
      raise SyntaxError("unexpected end in list")
    }
    if token_kind(tokens, next_expr) == CommaTok {
      continue next_expr + 1, _pos + 1
    }
    if token_kind(tokens, next_expr) == RBracketTok {
      break (
        located_expr(tokens, i - 1, next_expr + 1, List(items)),
        next_expr + 1,
      )
    }
    raise SyntaxError(
      "unexpected token in list: " + token_name(token_kind(tokens, next_expr)),
    )
  }
}

///|
fn parse_match_cases(
  tokens : Array[SpannedToken],
  i : Int,
) -> (Array[(MatchPattern, Expr?, Expr)], Int) raise {
  if i < tokens.length() && token_kind(tokens, i) == RBraceTok {
    return ([], i + 1)
  }
  let (case, j) = parse_match_case(tokens, i)
  let (rest, k) = parse_match_cases_tail(tokens, j)
  ([case] + rest, k)
}

///|
fn parse_match_cases_tail(
  tokens : Array[SpannedToken],
  i : Int,
) -> (Array[(MatchPattern, Expr?, Expr)], Int) raise {
  if i >= tokens.length() {
    raise SyntaxError("unexpected end in match")
  }
  if token_kind(tokens, i) == CommaTok {
    parse_match_cases(tokens, i + 1)
  } else if token_kind(tokens, i) == RBraceTok {
    ([], i + 1)
  } else {
    raise SyntaxError(
      "unexpected token in match: " + token_name(token_kind(tokens, i)),
    )
  }
}

///|
fn parse_match_case(
  tokens : Array[SpannedToken],
  i : Int,
) -> ((MatchPattern, Expr?, Expr), Int) raise {
  let (pattern, j) = parse_pattern(tokens, i)
  let (cond_expr, k) = if j < tokens.length() && token_kind(tokens, j) == IfTok {
    let (cond, next) = parse_expr(tokens, j + 1)
    (Some(cond), next)
  } else {
    (None, j)
  }
  if k >= tokens.length() || token_kind(tokens, k) != ArrowTok {
    raise SyntaxError("expected '=>' after match pattern")
  }
  let (body, next_expr) = parse_expr(tokens, k + 1)
  ((pattern, cond_expr, body), next_expr)
}

///|
fn parse_pattern(
  tokens : Array[SpannedToken],
  i : Int,
) -> (MatchPattern, Int) raise {
  let (pattern, j) = parse_pattern_atom(tokens, i)
  parse_pattern_or_tail(pattern, tokens, j)
}

///|
fn parse_pattern_or_tail(
  left : MatchPattern,
  tokens : Array[SpannedToken],
  i : Int,
) -> (MatchPattern, Int) raise {
  if i < tokens.length() && token_kind(tokens, i) == PipeTok {
    let (right, j) = parse_pattern_atom(tokens, i + 1)
    let combined = match left {
      POr(patterns) => POr(patterns + [right])
      _ => POr([left, right])
    }
    ensure_or_pattern_bindings(combined)
    parse_pattern_or_tail(combined, tokens, j)
  } else {
    (left, i)
  }
}

///|
fn parse_pattern_atom(
  tokens : Array[SpannedToken],
  i : Int,
) -> (MatchPattern, Int) raise {
  if i >= tokens.length() {
    raise SyntaxError("unexpected end in pattern")
  }
  match token_kind(tokens, i) {
    IdentTok(name) => (PBind(name), i + 1)
    IntTok(value) => (PInt(value), i + 1)
    StrTok(value) => (PString(value), i + 1)
    TrueTok => (PBool(true), i + 1)
    FalseTok => (PBool(false), i + 1)
    NilTok => (PNil, i + 1)
    HashTok => parse_variant_pattern(tokens, i + 1)
    LBracketTok => parse_list_pattern(tokens, i + 1)
    LBraceTok => parse_match_record_pattern(tokens, i + 1)
    tok => raise SyntaxError("unexpected token in pattern: " + token_name(tok))
  }
}

///|
fn ensure_or_pattern_bindings(pattern : MatchPattern) -> Unit raise {
  match pattern {
    POr(patterns) =>
      if patterns.length() > 0 {
        let expected = pattern_binding_names(patterns[0])
        ensure_or_pattern_bindings_all(patterns, expected, 1)
      }
    _ => ()
  }
}

///|
fn ensure_or_pattern_bindings_all(
  patterns : Array[MatchPattern],
  expected : Array[String],
  i : Int,
) -> Unit raise {
  if i >= patterns.length() {
    return
  }
  let actual = pattern_binding_names(patterns[i])
  if !same_binding_names(expected, actual) {
    raise SyntaxError(
      "all alternatives in an or-pattern must bind the same names",
    )
  }
  ensure_or_pattern_bindings_all(patterns, expected, i + 1)
}

///|
fn pattern_binding_names(pattern : MatchPattern) -> Array[String] {
  match pattern {
    PBind(name) => if name == "_" { [] } else { [name] }
    PInt(_) => []
    PBool(_) => []
    PString(_) => []
    PNil => []
    POr(patterns) =>
      if patterns.length() == 0 {
        []
      } else {
        pattern_binding_names(patterns[0])
      }
    PVariant(_, inner) => pattern_binding_names(inner)
    PList(items) =>
      items.fold(init=[], (acc, item) => acc + pattern_binding_names(item))
    PListRest(prefix, rest_name, suffix) => {
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
    PRecord(fields) =>
      fields.fold(init=[], (acc, field) => {
        let (_, field_pattern) = field
        acc + pattern_binding_names(field_pattern)
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
) -> (MatchPattern, Int) raise {
  if i >= tokens.length() {
    raise SyntaxError("expected variant name after '#'")
  }
  let tag = match token_kind(tokens, i) {
    IdentTok(name) => name
    tok => raise SyntaxError("expected variant name, found: " + token_name(tok))
  }
  if i + 1 >= tokens.length() || token_kind(tokens, i + 1) != LParenTok {
    raise SyntaxError("expected '(' after variant name")
  }
  let (inner, j) = parse_pattern(tokens, i + 2)
  if j >= tokens.length() || token_kind(tokens, j) != RParenTok {
    raise SyntaxError("expected ')' after variant pattern")
  }
  (PVariant(tag, inner), j + 1)
}

///|
fn parse_list_pattern(
  tokens : Array[SpannedToken],
  i : Int,
) -> (MatchPattern, Int) raise {
  if i < tokens.length() && token_kind(tokens, i) == RBracketTok {
    return (PList([]), i + 1)
  }
  let prefix = []
  for j = i, _pos = 0 {
    if j >= tokens.length() {
      raise SyntaxError("unexpected end in list pattern")
    }
    if token_kind(tokens, j) == DotDotTok {
      return parse_list_pattern_rest(tokens, j + 1, prefix)
    }
    let (pattern, next_pattern) = parse_pattern(tokens, j)
    prefix.push(pattern)
    if next_pattern >= tokens.length() {
      raise SyntaxError("unexpected end in list pattern")
    }
    if token_kind(tokens, next_pattern) == CommaTok {
      continue next_pattern + 1, _pos + 1
    }
    if token_kind(tokens, next_pattern) == RBracketTok {
      break (PList(prefix), next_pattern + 1)
    }
    raise SyntaxError(
      "unexpected token in list pattern: " +
      token_name(token_kind(tokens, next_pattern)),
    )
  }
}

///|
fn parse_list_pattern_rest(
  tokens : Array[SpannedToken],
  i : Int,
  prefix : Array[MatchPattern],
) -> (MatchPattern, Int) raise {
  if i >= tokens.length() {
    raise SyntaxError(
      "expected binding name, ',' or ']' after '..' in list pattern",
    )
  }
  let (rest_name, next_i) = match token_kind(tokens, i) {
    IdentTok(name) => (name, i + 1)
    CommaTok => ("_", i)
    RBracketTok => ("_", i)
    tok =>
      raise SyntaxError(
        "expected binding name, ',' or ']' after '..', found: " +
        token_name(tok),
      )
  }
  if next_i >= tokens.length() {
    raise SyntaxError("unexpected end in list pattern")
  }
  if token_kind(tokens, next_i) == RBracketTok {
    return (PListRest(prefix, rest_name, []), next_i + 1)
  }
  if token_kind(tokens, next_i) != CommaTok {
    raise SyntaxError(
      "expected ',' or ']' after list rest binding, found: " +
      token_name(token_kind(tokens, next_i)),
    )
  }
  let suffix = []
  for j = next_i + 1, _pos = 0 {
    if j >= tokens.length() {
      raise SyntaxError("unexpected end in list pattern")
    }
    if token_kind(tokens, j) == DotDotTok {
      raise SyntaxError("list pattern can contain at most one '..' binding")
    }
    let (pattern, next_pattern) = parse_pattern(tokens, j)
    suffix.push(pattern)
    if next_pattern >= tokens.length() {
      raise SyntaxError("unexpected end in list pattern")
    }
    if token_kind(tokens, next_pattern) == CommaTok {
      continue next_pattern + 1, _pos + 1
    }
    if token_kind(tokens, next_pattern) == RBracketTok {
      break (PListRest(prefix, rest_name, suffix), next_pattern + 1)
    }
    raise SyntaxError(
      "unexpected token in list pattern: " +
      token_name(token_kind(tokens, next_pattern)),
    )
  }
}

///|
fn parse_match_record_pattern(
  tokens : Array[SpannedToken],
  i : Int,
) -> (MatchPattern, Int) raise {
  if i < tokens.length() && token_kind(tokens, i) == RBraceTok {
    return (PRecord([]), i + 1)
  }
  let fields = []
  for j = i, _pos = 0 {
    if j >= tokens.length() {
      raise SyntaxError("unexpected end in record pattern")
    }
    let field_name = match token_kind(tokens, j) {
      IdentTok(name) => name
      tok => raise SyntaxError("expected field name, found: " + token_name(tok))
    }
    let (field_pattern, next) = if j + 1 < tokens.length() &&
      token_kind(tokens, j + 1) == ColonTok {
      let (pattern, k) = parse_pattern(tokens, j + 2)
      (pattern, k)
    } else {
      (PBind(field_name), j + 1)
    }
    fields.push((field_name, field_pattern))
    if next >= tokens.length() {
      raise SyntaxError("unexpected end in record pattern")
    }
    if token_kind(tokens, next) == CommaTok {
      continue next + 1, _pos + 1
    }
    if token_kind(tokens, next) == RBraceTok {
      break (PRecord(fields), next + 1)
    }
    raise SyntaxError(
      "unexpected token in record pattern: " +
      token_name(token_kind(tokens, next)),
    )
  }
}
