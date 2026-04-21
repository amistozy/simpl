///|
/// Parser error type
pub suberror ParseError {
  SyntaxError(String)
}

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
    raise SyntaxError("unexpected end")
  }
  if tokens[i] == EndTok {
    expr
  } else {
    raise SyntaxError(
      "unexpected token after expression: " + token_name(tokens[i]),
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
fn lex(source : String) -> Array[Token] raise {
  let tokens = []
  lex_loop(source, 0, tokens)
  tokens.push(EndTok)
  tokens
}

///|
fn lex_loop(source : String, i : Int, acc : Array[Token]) -> Unit raise {
  if i >= source.length() {
    return
  }
  let c = source.unsafe_get(i).unsafe_to_char()
  if c.is_ascii_whitespace() {
    return lex_loop(source, i + 1, acc)
  }
  if c.is_ascii_digit() {
    let end = scan_digits(source, i)
    let num_text = source[i:end].to_string()
    let value = parse_digits_to_int(num_text, 0, 0)
    acc.push(IntTok(value))
    return lex_loop(source, end, acc)
  }
  if is_ident_start(c) {
    let end = scan_ident(source, i)
    let text = source[i:end].to_string()
    let tok = keyword_or_ident(text)
    acc.push(tok)
    return lex_loop(source, end, acc)
  }
  match c {
    '"' => {
      let end = scan_string_end(source, i + 1)
      let content = source[i + 1:end].to_string()
      acc.push(StrTok(content))
      lex_loop(source, end + 1, acc)
    }
    '(' => {
      acc.push(LParenTok)
      lex_loop(source, i + 1, acc)
    }
    ')' => {
      acc.push(RParenTok)
      lex_loop(source, i + 1, acc)
    }
    ',' => {
      acc.push(CommaTok)
      lex_loop(source, i + 1, acc)
    }
    ';' => {
      acc.push(SemiTok)
      lex_loop(source, i + 1, acc)
    }
    '+' => {
      acc.push(PlusTok)
      lex_loop(source, i + 1, acc)
    }
    '-' => {
      acc.push(MinusTok)
      lex_loop(source, i + 1, acc)
    }
    '*' => {
      acc.push(StarTok)
      lex_loop(source, i + 1, acc)
    }
    '/' => {
      acc.push(SlashTok)
      lex_loop(source, i + 1, acc)
    }
    '>' =>
      if i + 1 < source.length() &&
        source.unsafe_get(i + 1).unsafe_to_char() == '=' {
        acc.push(GeTok)
        lex_loop(source, i + 2, acc)
      } else {
        acc.push(GtTok)
        lex_loop(source, i + 1, acc)
      }
    '<' =>
      if i + 1 < source.length() &&
        source.unsafe_get(i + 1).unsafe_to_char() == '=' {
        acc.push(LeTok)
        lex_loop(source, i + 2, acc)
      } else {
        acc.push(LtTok)
        lex_loop(source, i + 1, acc)
      }
    '=' =>
      if i + 1 < source.length() {
        let n = source.unsafe_get(i + 1).unsafe_to_char()
        if n == '=' {
          acc.push(EqEqTok)
          lex_loop(source, i + 2, acc)
        } else if n == '>' {
          acc.push(ArrowTok)
          lex_loop(source, i + 2, acc)
        } else {
          acc.push(AssignTok)
          lex_loop(source, i + 1, acc)
        }
      } else {
        acc.push(AssignTok)
        lex_loop(source, i + 1, acc)
      }
    '!' =>
      if i + 1 < source.length() &&
        source.unsafe_get(i + 1).unsafe_to_char() == '=' {
        acc.push(BangEqTok)
        lex_loop(source, i + 2, acc)
      } else {
        acc.push(BangTok)
        lex_loop(source, i + 1, acc)
      }
    ':' =>
      if i + 1 < source.length() &&
        source.unsafe_get(i + 1).unsafe_to_char() == '=' {
        acc.push(ColonEqTok)
        lex_loop(source, i + 2, acc)
      } else {
        acc.push(ColonTok)
        lex_loop(source, i + 1, acc)
      }
    '.' => {
      acc.push(DotTok)
      lex_loop(source, i + 1, acc)
    }
    '#' => {
      acc.push(HashTok)
      lex_loop(source, i + 1, acc)
    }
    '{' => {
      acc.push(LBraceTok)
      lex_loop(source, i + 1, acc)
    }
    '}' => {
      acc.push(RBraceTok)
      lex_loop(source, i + 1, acc)
    }
    '[' => {
      acc.push(LBracketTok)
      lex_loop(source, i + 1, acc)
    }
    ']' => {
      acc.push(RBracketTok)
      lex_loop(source, i + 1, acc)
    }
    '&' =>
      if i + 1 < source.length() &&
        source.unsafe_get(i + 1).unsafe_to_char() == '&' {
        acc.push(AndAndTok)
        lex_loop(source, i + 2, acc)
      } else {
        raise SyntaxError("unexpected token '&'")
      }
    '|' =>
      if i + 1 < source.length() &&
        source.unsafe_get(i + 1).unsafe_to_char() == '|' {
        acc.push(OrOrTok)
        lex_loop(source, i + 2, acc)
      } else {
        raise SyntaxError("unexpected token '|'")
      }
    _ => raise SyntaxError("unexpected character: " + c.to_string())
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
fn parse_expr(tokens : Array[Token], i : Int) -> (Expr, Int) raise {
  parse_seq_expr(tokens, i)
}

///|
fn parse_seq_expr(tokens : Array[Token], i : Int) -> (Expr, Int) raise {
  let (left, j) = parse_assign_expr(tokens, i)
  if j < tokens.length() && tokens[j] == SemiTok {
    let (right, k) = parse_seq_expr(tokens, j + 1)
    (Let("_", left, right), k)
  } else {
    (left, j)
  }
}

///|
fn parse_assign_expr(tokens : Array[Token], i : Int) -> (Expr, Int) raise {
  let (left, j) = parse_let_expr(tokens, i)
  if j < tokens.length() && tokens[j] == ColonEqTok {
    let (right, k) = parse_assign_expr(tokens, j + 1)
    (RefSet(left, right), k)
  } else {
    (left, j)
  }
}

///|
fn parse_let_expr(tokens : Array[Token], i : Int) -> (Expr, Int) raise {
  if i >= tokens.length() {
    raise SyntaxError("unexpected end")
  }
  if tokens[i] == LetTok {
    if i + 1 < tokens.length() && tokens[i + 1] == RecTok {
      parse_let_rec_expr(tokens, i + 2)
    } else {
      parse_plain_let_expr(tokens, i + 1)
    }
  } else {
    parse_if_expr(tokens, i)
  }
}

///|
fn parse_plain_let_expr(tokens : Array[Token], i : Int) -> (Expr, Int) raise {
  if i >= tokens.length() {
    raise SyntaxError("expected identifier after 'let'")
  }
  if tokens[i] == LBraceTok {
    let (bindings, j) = parse_record_pattern(tokens, i + 1)
    if j >= tokens.length() || tokens[j] != AssignTok {
      raise SyntaxError("expected '=' after record pattern")
    }
    let (value_expr, k) = parse_expr(tokens, j + 1)
    if k >= tokens.length() || tokens[k] != InTok {
      raise SyntaxError("expected 'in' after let binding")
    }
    let (body, m) = parse_expr(tokens, k + 1)
    (LetRecord(bindings, value_expr, body), m)
  } else {
    match tokens[i] {
      IdentTok(name) =>
        if i + 1 < tokens.length() && tokens[i + 1] == LParenTok {
          let (params, j) = parse_params(tokens, i + 2)
          if j >= tokens.length() || tokens[j] != AssignTok {
            raise SyntaxError("expected '=' after let function params")
          }
          let (func_body, k) = parse_expr(tokens, j + 1)
          if k >= tokens.length() || tokens[k] != InTok {
            raise SyntaxError("expected 'in' after let function binding")
          }
          let (body, m) = parse_expr(tokens, k + 1)
          (Let(name, Lambda(params, func_body), body), m)
        } else if i + 1 < tokens.length() && tokens[i + 1] == AssignTok {
          let (value_expr, j) = parse_expr(tokens, i + 2)
          if j >= tokens.length() || tokens[j] != InTok {
            raise SyntaxError("expected 'in' after let binding")
          }
          let (body, k) = parse_expr(tokens, j + 1)
          (Let(name, value_expr, body), k)
        } else {
          raise SyntaxError("expected '=' after let name")
        }
      _ => raise SyntaxError("expected identifier after 'let'")
    }
  }
}

///|
fn parse_let_rec_expr(tokens : Array[Token], i : Int) -> (Expr, Int) raise {
  if i >= tokens.length() {
    raise SyntaxError("expected function name after 'let rec'")
  }
  match tokens[i] {
    IdentTok(name) => {
      if i + 1 >= tokens.length() || tokens[i + 1] != LParenTok {
        raise SyntaxError("expected '(...)' after let rec function name")
      }
      let (params, j) = parse_params(tokens, i + 2)
      if j >= tokens.length() || tokens[j] != AssignTok {
        raise SyntaxError("expected '=' after let rec params")
      }
      let (func_body, k) = parse_expr(tokens, j + 1)
      if k >= tokens.length() || tokens[k] != InTok {
        raise SyntaxError("expected 'in' after let rec binding")
      }
      let (body, m) = parse_expr(tokens, k + 1)
      (LetRec(name, params, func_body, body), m)
    }
    _ => raise SyntaxError("expected function name after 'let rec'")
  }
}

///|
fn parse_if_expr(tokens : Array[Token], i : Int) -> (Expr, Int) raise {
  if i < tokens.length() && tokens[i] == IfTok {
    let (cond, j) = parse_expr(tokens, i + 1)
    if j >= tokens.length() || tokens[j] != ThenTok {
      raise SyntaxError("expected 'then' in if expression")
    }
    let (then_expr, k) = parse_expr(tokens, j + 1)
    if k >= tokens.length() || tokens[k] != ElseTok {
      raise SyntaxError("expected 'else' in if expression")
    }
    let (else_expr, m) = parse_expr(tokens, k + 1)
    (If(cond, then_expr, else_expr), m)
  } else {
    parse_match_expr(tokens, i)
  }
}

///|
fn parse_match_expr(tokens : Array[Token], i : Int) -> (Expr, Int) raise {
  if i < tokens.length() && tokens[i] == MatchTok {
    let (value_expr, j) = parse_expr(tokens, i + 1)
    if j >= tokens.length() || tokens[j] != LBraceTok {
      raise SyntaxError("expected '{' after match expression")
    }
    let (cases, k) = parse_match_cases(tokens, j + 1)
    (Match(value_expr, cases), k)
  } else {
    parse_lambda_expr(tokens, i)
  }
}

///|
fn parse_lambda_expr(tokens : Array[Token], i : Int) -> (Expr, Int) raise {
  if i < tokens.length() && tokens[i] == FnTok {
    if i + 1 >= tokens.length() || tokens[i + 1] != LParenTok {
      raise SyntaxError("expected '(' after 'fn'")
    }
    let (params, j) = parse_params(tokens, i + 2)
    if j >= tokens.length() || tokens[j] != ArrowTok {
      raise SyntaxError("expected '=>' after lambda params")
    }
    let (body, k) = parse_expr(tokens, j + 1)
    (Lambda(params, body), k)
  } else {
    parse_or_expr(tokens, i)
  }
}

///|
fn parse_params(tokens : Array[Token], i : Int) -> (Array[String], Int) raise {
  if i >= tokens.length() {
    raise SyntaxError("unexpected end in params")
  }
  if tokens[i] == RParenTok {
    ([], i + 1)
  } else {
    parse_params_nonempty(tokens, i)
  }
}

///|
fn parse_params_nonempty(
  tokens : Array[Token],
  i : Int,
) -> (Array[String], Int) raise {
  let params = []
  for j = i, _pos = 0 {
    if j >= tokens.length() {
      raise SyntaxError("unexpected end in params")
    }
    match tokens[j] {
      IdentTok(name) => params.push(name)
      tok => raise SyntaxError("expected param name, found: " + token_name(tok))
    }
    let next = j + 1
    if next >= tokens.length() {
      raise SyntaxError("unexpected end in params")
    }
    if tokens[next] == CommaTok {
      continue next + 1, _pos + 1
    }
    if tokens[next] == RParenTok {
      break (params, next + 1)
    }
    raise SyntaxError("unexpected token in params: " + token_name(tokens[next]))
  }
}

///|
fn parse_or_expr(tokens : Array[Token], i : Int) -> (Expr, Int) raise {
  let (left, j) = parse_and_expr(tokens, i)
  parse_or_tail(left, tokens, j)
}

///|
fn parse_or_tail(
  left : Expr,
  tokens : Array[Token],
  i : Int,
) -> (Expr, Int) raise {
  if i < tokens.length() && (tokens[i] == OrOrTok || tokens[i] == OrWordTok) {
    let (right, j) = parse_and_expr(tokens, i + 1)
    parse_or_tail(Binary(Or, left, right), tokens, j)
  } else {
    (left, i)
  }
}

///|
fn parse_and_expr(tokens : Array[Token], i : Int) -> (Expr, Int) raise {
  let (left, j) = parse_eq_expr(tokens, i)
  parse_and_tail(left, tokens, j)
}

///|
fn parse_and_tail(
  left : Expr,
  tokens : Array[Token],
  i : Int,
) -> (Expr, Int) raise {
  if i < tokens.length() && (tokens[i] == AndAndTok || tokens[i] == AndWordTok) {
    let (right, j) = parse_eq_expr(tokens, i + 1)
    parse_and_tail(Binary(And, left, right), tokens, j)
  } else {
    (left, i)
  }
}

///|
fn parse_eq_expr(tokens : Array[Token], i : Int) -> (Expr, Int) raise {
  let (left, j) = parse_cmp_expr(tokens, i)
  parse_eq_tail(left, tokens, j)
}

///|
fn parse_eq_tail(
  left : Expr,
  tokens : Array[Token],
  i : Int,
) -> (Expr, Int) raise {
  if i < tokens.length() && tokens[i] == EqEqTok {
    let (right, j) = parse_cmp_expr(tokens, i + 1)
    parse_eq_tail(Binary(Eq, left, right), tokens, j)
  } else if i < tokens.length() && tokens[i] == BangEqTok {
    let (right, j) = parse_cmp_expr(tokens, i + 1)
    parse_eq_tail(Binary(Ne, left, right), tokens, j)
  } else {
    (left, i)
  }
}

///|
fn parse_cmp_expr(tokens : Array[Token], i : Int) -> (Expr, Int) raise {
  let (left, j) = parse_add_expr(tokens, i)
  parse_cmp_tail(left, tokens, j)
}

///|
fn parse_cmp_tail(
  left : Expr,
  tokens : Array[Token],
  i : Int,
) -> (Expr, Int) raise {
  if i < tokens.length() && tokens[i] == LtTok {
    let (right, j) = parse_add_expr(tokens, i + 1)
    parse_cmp_tail(Binary(Lt, left, right), tokens, j)
  } else if i < tokens.length() && tokens[i] == LeTok {
    let (right, j) = parse_add_expr(tokens, i + 1)
    parse_cmp_tail(Binary(Le, left, right), tokens, j)
  } else if i < tokens.length() && tokens[i] == GtTok {
    let (right, j) = parse_add_expr(tokens, i + 1)
    parse_cmp_tail(Binary(Gt, left, right), tokens, j)
  } else if i < tokens.length() && tokens[i] == GeTok {
    let (right, j) = parse_add_expr(tokens, i + 1)
    parse_cmp_tail(Binary(Ge, left, right), tokens, j)
  } else {
    (left, i)
  }
}

///|
fn parse_add_expr(tokens : Array[Token], i : Int) -> (Expr, Int) raise {
  let (left, j) = parse_mul_expr(tokens, i)
  parse_add_tail(left, tokens, j)
}

///|
fn parse_add_tail(
  left : Expr,
  tokens : Array[Token],
  i : Int,
) -> (Expr, Int) raise {
  if i < tokens.length() && tokens[i] == PlusTok {
    let (right, j) = parse_mul_expr(tokens, i + 1)
    parse_add_tail(Binary(Add, left, right), tokens, j)
  } else if i < tokens.length() && tokens[i] == MinusTok {
    let (right, j) = parse_mul_expr(tokens, i + 1)
    parse_add_tail(Binary(Sub, left, right), tokens, j)
  } else {
    (left, i)
  }
}

///|
fn parse_mul_expr(tokens : Array[Token], i : Int) -> (Expr, Int) raise {
  let (left, j) = parse_unary_expr(tokens, i)
  parse_mul_tail(left, tokens, j)
}

///|
fn parse_mul_tail(
  left : Expr,
  tokens : Array[Token],
  i : Int,
) -> (Expr, Int) raise {
  if i < tokens.length() && tokens[i] == StarTok {
    let (right, j) = parse_unary_expr(tokens, i + 1)
    parse_mul_tail(Binary(Mul, left, right), tokens, j)
  } else if i < tokens.length() && tokens[i] == SlashTok {
    let (right, j) = parse_unary_expr(tokens, i + 1)
    parse_mul_tail(Binary(Div, left, right), tokens, j)
  } else {
    (left, i)
  }
}

///|
fn parse_unary_expr(tokens : Array[Token], i : Int) -> (Expr, Int) raise {
  if i < tokens.length() && tokens[i] == RefTok {
    let (expr, j) = parse_unary_expr(tokens, i + 1)
    (RefNew(expr), j)
  } else if i < tokens.length() && tokens[i] == BangTok {
    let (expr, j) = parse_unary_expr(tokens, i + 1)
    (RefGet(expr), j)
  } else if i < tokens.length() && tokens[i] == MinusTok {
    let (expr, j) = parse_unary_expr(tokens, i + 1)
    (Unary(Neg, expr), j)
  } else if i < tokens.length() && tokens[i] == NotTok {
    let (expr, j) = parse_unary_expr(tokens, i + 1)
    (Unary(Not, expr), j)
  } else {
    parse_postfix_expr(tokens, i)
  }
}

///|
fn parse_postfix_expr(tokens : Array[Token], i : Int) -> (Expr, Int) raise {
  let (expr, j) = parse_primary_expr(tokens, i)
  parse_postfix_tail(expr, tokens, j)
}

///|
fn parse_postfix_tail(
  expr : Expr,
  tokens : Array[Token],
  i : Int,
) -> (Expr, Int) raise {
  if i < tokens.length() && tokens[i] == LParenTok {
    let (args, j) = parse_args(tokens, i + 1)
    parse_postfix_tail(Call(expr, args), tokens, j)
  } else if i < tokens.length() && tokens[i] == DotTok {
    if i + 1 >= tokens.length() {
      raise SyntaxError("expected field name after '.'")
    }
    match tokens[i + 1] {
      IdentTok(name) => parse_postfix_tail(Field(expr, name), tokens, i + 2)
      tok => raise SyntaxError("expected field name, found: " + token_name(tok))
    }
  } else {
    (expr, i)
  }
}

///|
fn parse_args(tokens : Array[Token], i : Int) -> (Array[Expr], Int) raise {
  if i >= tokens.length() {
    raise SyntaxError("unexpected end in args")
  }
  if tokens[i] == RParenTok {
    ([], i + 1)
  } else {
    parse_args_nonempty(tokens, i)
  }
}

///|
fn parse_args_nonempty(
  tokens : Array[Token],
  i : Int,
) -> (Array[Expr], Int) raise {
  let args = []
  for j = i, _pos = 0 {
    let (arg, next_expr) = parse_expr(tokens, j)
    args.push(arg)
    if next_expr >= tokens.length() {
      raise SyntaxError("unexpected end in args")
    }
    if tokens[next_expr] == CommaTok {
      continue next_expr + 1, _pos + 1
    }
    if tokens[next_expr] == RParenTok {
      break (args, next_expr + 1)
    }
    raise SyntaxError(
      "unexpected token in args: " + token_name(tokens[next_expr]),
    )
  }
}

///|
fn parse_primary_expr(tokens : Array[Token], i : Int) -> (Expr, Int) raise {
  if i >= tokens.length() {
    raise SyntaxError("unexpected end")
  }
  match tokens[i] {
    IntTok(v) => (IntLit(v), i + 1)
    StrTok(v) => (StringLit(v), i + 1)
    TrueTok => (BoolLit(true), i + 1)
    FalseTok => (BoolLit(false), i + 1)
    NilTok => (NilLit, i + 1)
    IdentTok(name) => (Var(name), i + 1)
    HashTok => parse_variant_literal(tokens, i + 1)
    LBraceTok => parse_record_literal(tokens, i + 1)
    LBracketTok => parse_list_literal(tokens, i + 1)
    LParenTok => {
      let (expr, j) = parse_expr(tokens, i + 1)
      if j < tokens.length() && tokens[j] == RParenTok {
        (expr, j + 1)
      } else if j < tokens.length() {
        raise SyntaxError("expected ')', found: " + token_name(tokens[j]))
      } else {
        raise SyntaxError("expected ')' but found end")
      }
    }
    tok => raise SyntaxError("unexpected token: " + token_name(tok))
  }
}

///|
fn parse_variant_literal(tokens : Array[Token], i : Int) -> (Expr, Int) raise {
  if i >= tokens.length() {
    raise SyntaxError("expected variant name after '#'")
  }
  match tokens[i] {
    IdentTok(tag) => {
      if i + 1 >= tokens.length() || tokens[i + 1] != LParenTok {
        raise SyntaxError("expected '(' after variant tag")
      }
      let (value_expr, j) = parse_expr(tokens, i + 2)
      if j >= tokens.length() || tokens[j] != RParenTok {
        raise SyntaxError("expected ')' after variant payload")
      }
      (Variant(tag, value_expr), j + 1)
    }
    tok => raise SyntaxError("expected variant name, found: " + token_name(tok))
  }
}

///|
fn parse_record_literal(tokens : Array[Token], i : Int) -> (Expr, Int) raise {
  if i < tokens.length() && tokens[i] == RBraceTok {
    return (Record([]), i + 1)
  }
  let fields = []
  for j = i, _pos = 0 {
    if j >= tokens.length() {
      raise SyntaxError("unexpected end in record")
    }
    let name = match tokens[j] {
      IdentTok(field_name) => field_name
      tok => raise SyntaxError("expected field name, found: " + token_name(tok))
    }
    if j + 1 >= tokens.length() || tokens[j + 1] != ColonTok {
      raise SyntaxError("expected ':' after field name")
    }
    let (value_expr, next_expr) = parse_expr(tokens, j + 2)
    fields.push((name, value_expr))
    if next_expr >= tokens.length() {
      raise SyntaxError("unexpected end in record")
    }
    if tokens[next_expr] == CommaTok {
      continue next_expr + 1, _pos + 1
    }
    if tokens[next_expr] == RBraceTok {
      break (Record(fields), next_expr + 1)
    }
    raise SyntaxError(
      "unexpected token in record: " + token_name(tokens[next_expr]),
    )
  }
}

///|
fn parse_list_literal(tokens : Array[Token], i : Int) -> (Expr, Int) raise {
  if i < tokens.length() && tokens[i] == RBracketTok {
    return (List([]), i + 1)
  }
  let items = []
  for j = i, _pos = 0 {
    let (item, next_expr) = parse_expr(tokens, j)
    items.push(item)
    if next_expr >= tokens.length() {
      raise SyntaxError("unexpected end in list")
    }
    if tokens[next_expr] == CommaTok {
      continue next_expr + 1, _pos + 1
    }
    if tokens[next_expr] == RBracketTok {
      break (List(items), next_expr + 1)
    }
    raise SyntaxError(
      "unexpected token in list: " + token_name(tokens[next_expr]),
    )
  }
}

///|
fn parse_match_cases(
  tokens : Array[Token],
  i : Int,
) -> (Array[(MatchPattern, Expr)], Int) raise {
  if i < tokens.length() && tokens[i] == RBraceTok {
    return ([], i + 1)
  }
  let (case, j) = parse_match_case(tokens, i)
  let (rest, k) = parse_match_cases_tail(tokens, j)
  ([case] + rest, k)
}

///|
fn parse_match_cases_tail(
  tokens : Array[Token],
  i : Int,
) -> (Array[(MatchPattern, Expr)], Int) raise {
  if i >= tokens.length() {
    raise SyntaxError("unexpected end in match")
  }
  if tokens[i] == CommaTok {
    parse_match_cases(tokens, i + 1)
  } else if tokens[i] == RBraceTok {
    ([], i + 1)
  } else {
    raise SyntaxError("unexpected token in match: " + token_name(tokens[i]))
  }
}

///|
fn parse_match_case(
  tokens : Array[Token],
  i : Int,
) -> ((MatchPattern, Expr), Int) raise {
  let (pattern, j) = parse_pattern(tokens, i)
  if j >= tokens.length() || tokens[j] != ArrowTok {
    raise SyntaxError("expected '=>' after match pattern")
  }
  let (body, next_expr) = parse_expr(tokens, j + 1)
  ((pattern, body), next_expr)
}

///|
fn parse_pattern(tokens : Array[Token], i : Int) -> (MatchPattern, Int) raise {
  if i >= tokens.length() {
    raise SyntaxError("unexpected end in pattern")
  }
  match tokens[i] {
    IdentTok(name) => (PBind(name), i + 1)
    HashTok => parse_variant_pattern(tokens, i + 1)
    LBracketTok => parse_list_pattern(tokens, i + 1)
    tok => raise SyntaxError("unexpected token in pattern: " + token_name(tok))
  }
}

///|
fn parse_variant_pattern(
  tokens : Array[Token],
  i : Int,
) -> (MatchPattern, Int) raise {
  if i >= tokens.length() {
    raise SyntaxError("expected variant name after '#'")
  }
  let tag = match tokens[i] {
    IdentTok(name) => name
    tok => raise SyntaxError("expected variant name, found: " + token_name(tok))
  }
  if i + 1 >= tokens.length() || tokens[i + 1] != LParenTok {
    raise SyntaxError("expected '(' after variant name")
  }
  let (inner, j) = parse_pattern(tokens, i + 2)
  if j >= tokens.length() || tokens[j] != RParenTok {
    raise SyntaxError("expected ')' after variant pattern")
  }
  (PVariant(tag, inner), j + 1)
}

///|
fn parse_list_pattern(
  tokens : Array[Token],
  i : Int,
) -> (MatchPattern, Int) raise {
  if i < tokens.length() && tokens[i] == RBracketTok {
    return (PList([]), i + 1)
  }
  let items = []
  for j = i, _pos = 0 {
    let (pattern, next_pattern) = parse_pattern(tokens, j)
    items.push(pattern)
    if next_pattern >= tokens.length() {
      raise SyntaxError("unexpected end in list pattern")
    }
    if tokens[next_pattern] == CommaTok {
      continue next_pattern + 1, _pos + 1
    }
    if tokens[next_pattern] == RBracketTok {
      break (PList(items), next_pattern + 1)
    }
    raise SyntaxError(
      "unexpected token in list pattern: " + token_name(tokens[next_pattern]),
    )
  }
}

///|
fn parse_record_pattern(
  tokens : Array[Token],
  i : Int,
) -> (Array[(String, String)], Int) raise {
  if i < tokens.length() && tokens[i] == RBraceTok {
    return ([], i + 1)
  }
  let bindings = []
  for j = i, _pos = 0 {
    if j >= tokens.length() {
      raise SyntaxError("unexpected end in record pattern")
    }
    let field_name = match tokens[j] {
      IdentTok(name) => name
      tok => raise SyntaxError("expected field name, found: " + token_name(tok))
    }
    let local_name = if j + 1 < tokens.length() && tokens[j + 1] == ColonTok {
      if j + 2 >= tokens.length() {
        raise SyntaxError("expected name after ':'")
      }
      match tokens[j + 2] {
        IdentTok(rename) => rename
        tok =>
          raise SyntaxError(
            "expected name after ':', found: " + token_name(tok),
          )
      }
    } else {
      field_name
    }
    let next = if j + 1 < tokens.length() && tokens[j + 1] == ColonTok {
      j + 3
    } else {
      j + 1
    }
    bindings.push((field_name, local_name))
    if next >= tokens.length() {
      raise SyntaxError("unexpected end in record pattern")
    }
    if tokens[next] == CommaTok {
      continue next + 1, _pos + 1
    }
    if tokens[next] == RBraceTok {
      break (bindings, next + 1)
    }
    raise SyntaxError(
      "unexpected token in record pattern: " + token_name(tokens[next]),
    )
  }
}
