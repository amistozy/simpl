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
  InTok
  IfTok
  ThenTok
  ElseTok
  FnTok
  NotTok
  AndWordTok
  OrWordTok
  PlusTok
  MinusTok
  StarTok
  SlashTok
  EqEqTok
  LtTok
  GtTok
  AndAndTok
  OrOrTok
  AssignTok
  ArrowTok
  LParenTok
  RParenTok
  CommaTok
  EndTok
}

///|
pub fn parse(source : String) -> Expr raise {
  let tokens = lex(source)
  let (expr, rest) = parse_expr(tokens)
  match rest {
    More(EndTok, tail=_) => expr
    More(tok, tail=_) =>
      raise SyntaxError("unexpected token after expression: " + token_name(tok))
    @list.Empty => raise SyntaxError("unexpected end")
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
fn lex(source : String) -> @list.List[Token] raise {
  reverse_tokens(@list.cons(EndTok, lex_loop(source, 0, @list.empty())))
}

///|
fn lex_loop(
  source : String,
  i : Int,
  acc : @list.List[Token],
) -> @list.List[Token] raise {
  if i >= source.length() {
    return acc
  }
  let c = source.unsafe_get(i).unsafe_to_char()
  if c.is_ascii_whitespace() {
    return lex_loop(source, i + 1, acc)
  }
  if c.is_ascii_digit() {
    let end = scan_digits(source, i)
    let num_text = source[i:end].to_string()
    let value = parse_digits_to_int(num_text, 0, 0)
    return lex_loop(source, end, @list.cons(IntTok(value), acc))
  }
  if is_ident_start(c) {
    let end = scan_ident(source, i)
    let text = source[i:end].to_string()
    let tok = keyword_or_ident(text)
    return lex_loop(source, end, @list.cons(tok, acc))
  }
  match c {
    '"' => {
      let end = scan_string_end(source, i + 1)
      let content = source[i + 1:end].to_string()
      lex_loop(source, end + 1, @list.cons(StrTok(content), acc))
    }
    '(' => lex_loop(source, i + 1, @list.cons(LParenTok, acc))
    ')' => lex_loop(source, i + 1, @list.cons(RParenTok, acc))
    ',' => lex_loop(source, i + 1, @list.cons(CommaTok, acc))
    '+' => lex_loop(source, i + 1, @list.cons(PlusTok, acc))
    '-' => lex_loop(source, i + 1, @list.cons(MinusTok, acc))
    '*' => lex_loop(source, i + 1, @list.cons(StarTok, acc))
    '/' => lex_loop(source, i + 1, @list.cons(SlashTok, acc))
    '<' => lex_loop(source, i + 1, @list.cons(LtTok, acc))
    '>' => lex_loop(source, i + 1, @list.cons(GtTok, acc))
    '=' =>
      if i + 1 < source.length() {
        let n = source.unsafe_get(i + 1).unsafe_to_char()
        if n == '=' {
          lex_loop(source, i + 2, @list.cons(EqEqTok, acc))
        } else if n == '>' {
          lex_loop(source, i + 2, @list.cons(ArrowTok, acc))
        } else {
          lex_loop(source, i + 1, @list.cons(AssignTok, acc))
        }
      } else {
        lex_loop(source, i + 1, @list.cons(AssignTok, acc))
      }
    '&' =>
      if i + 1 < source.length() &&
        source.unsafe_get(i + 1).unsafe_to_char() == '&' {
        lex_loop(source, i + 2, @list.cons(AndAndTok, acc))
      } else {
        raise SyntaxError("unexpected token '&'")
      }
    '|' =>
      if i + 1 < source.length() &&
        source.unsafe_get(i + 1).unsafe_to_char() == '|' {
        lex_loop(source, i + 2, @list.cons(OrOrTok, acc))
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
    "in" => InTok
    "if" => IfTok
    "then" => ThenTok
    "else" => ElseTok
    "fn" => FnTok
    "not" => NotTok
    "and" => AndWordTok
    "or" => OrWordTok
    _ => IdentTok(text)
  }
}

///|
fn reverse_tokens(tokens : @list.List[Token]) -> @list.List[Token] {
  reverse_tokens_with_acc(tokens, @list.empty())
}

///|
fn reverse_tokens_with_acc(
  tokens : @list.List[Token],
  acc : @list.List[Token],
) -> @list.List[Token] {
  match tokens {
    @list.Empty => acc
    More(head, tail~) => reverse_tokens_with_acc(tail, @list.cons(head, acc))
  }
}

///|
fn reverse_exprs(xs : @list.List[Expr]) -> @list.List[Expr] {
  reverse_exprs_with_acc(xs, @list.empty())
}

///|
fn reverse_exprs_with_acc(
  xs : @list.List[Expr],
  acc : @list.List[Expr],
) -> @list.List[Expr] {
  match xs {
    @list.Empty => acc
    More(head, tail~) => reverse_exprs_with_acc(tail, @list.cons(head, acc))
  }
}

///|
fn reverse_strings(xs : @list.List[String]) -> @list.List[String] {
  reverse_strings_with_acc(xs, @list.empty())
}

///|
fn reverse_strings_with_acc(
  xs : @list.List[String],
  acc : @list.List[String],
) -> @list.List[String] {
  match xs {
    @list.Empty => acc
    More(head, tail~) => reverse_strings_with_acc(tail, @list.cons(head, acc))
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
    InTok => "in"
    IfTok => "if"
    ThenTok => "then"
    ElseTok => "else"
    FnTok => "fn"
    NotTok => "not"
    AndWordTok => "and"
    OrWordTok => "or"
    PlusTok => "+"
    MinusTok => "-"
    StarTok => "*"
    SlashTok => "/"
    EqEqTok => "=="
    LtTok => "<"
    GtTok => ">"
    AndAndTok => "&&"
    OrOrTok => "||"
    AssignTok => "="
    ArrowTok => "=>"
    LParenTok => "("
    RParenTok => ")"
    CommaTok => ","
    EndTok => "<eof>"
  }
}

///|
fn parse_expr(tokens : @list.List[Token]) -> (Expr, @list.List[Token]) raise {
  parse_let_expr(tokens)
}

///|
fn parse_let_expr(
  tokens : @list.List[Token],
) -> (Expr, @list.List[Token]) raise {
  match tokens {
    More(LetTok, tail=rest1) =>
      match rest1 {
        More(IdentTok(name), tail=More(AssignTok, tail=rest3)) => {
          let (value_expr, rest4) = parse_expr(rest3)
          match rest4 {
            More(InTok, tail=rest5) => {
              let (body, rest6) = parse_expr(rest5)
              (Let(name, value_expr, body), rest6)
            }
            _ => raise SyntaxError("expected 'in' after let binding")
          }
        }
        More(IdentTok(_), tail=_) =>
          raise SyntaxError("expected '=' after let name")
        _ => raise SyntaxError("expected identifier after 'let'")
      }
    _ => parse_if_expr(tokens)
  }
}

///|
fn parse_if_expr(tokens : @list.List[Token]) -> (Expr, @list.List[Token]) raise {
  match tokens {
    More(IfTok, tail=rest1) => {
      let (cond, rest2) = parse_expr(rest1)
      match rest2 {
        More(ThenTok, tail=rest3) => {
          let (then_expr, rest4) = parse_expr(rest3)
          match rest4 {
            More(ElseTok, tail=rest5) => {
              let (else_expr, rest6) = parse_expr(rest5)
              (If(cond, then_expr, else_expr), rest6)
            }
            _ => raise SyntaxError("expected 'else' in if expression")
          }
        }
        _ => raise SyntaxError("expected 'then' in if expression")
      }
    }
    _ => parse_lambda_expr(tokens)
  }
}

///|
fn parse_lambda_expr(
  tokens : @list.List[Token],
) -> (Expr, @list.List[Token]) raise {
  match tokens {
    More(FnTok, tail=More(LParenTok, tail=rest2)) => {
      let (params, rest3) = parse_params(rest2)
      match rest3 {
        More(ArrowTok, tail=rest4) => {
          let (body, rest5) = parse_expr(rest4)
          (Lambda(params, body), rest5)
        }
        _ => raise SyntaxError("expected '=>' after lambda params")
      }
    }
    More(FnTok, tail=_) => raise SyntaxError("expected '(' after 'fn'")
    _ => parse_or_expr(tokens)
  }
}

///|
fn parse_params(
  tokens : @list.List[Token],
) -> (@list.List[String], @list.List[Token]) raise {
  match tokens {
    More(RParenTok, tail=rest) => (@list.empty(), rest)
    _ => {
      let (params_rev, rest) = parse_params_nonempty(tokens, @list.empty())
      (reverse_strings(params_rev), rest)
    }
  }
}

///|
fn parse_params_nonempty(
  tokens : @list.List[Token],
  acc : @list.List[String],
) -> (@list.List[String], @list.List[Token]) raise {
  match tokens {
    More(IdentTok(name), tail=rest1) =>
      match rest1 {
        More(CommaTok, tail=rest2) =>
          parse_params_nonempty(rest2, @list.cons(name, acc))
        More(RParenTok, tail=rest2) => (@list.cons(name, acc), rest2)
        More(tok, tail=_) =>
          raise SyntaxError("unexpected token in params: " + token_name(tok))
        @list.Empty => raise SyntaxError("unexpected end in params")
      }
    More(tok, tail=_) =>
      raise SyntaxError("expected param name, found: " + token_name(tok))
    @list.Empty => raise SyntaxError("unexpected end in params")
  }
}

///|
fn parse_or_expr(tokens : @list.List[Token]) -> (Expr, @list.List[Token]) raise {
  let (left, rest) = parse_and_expr(tokens)
  parse_or_tail(left, rest)
}

///|
fn parse_or_tail(
  left : Expr,
  tokens : @list.List[Token],
) -> (Expr, @list.List[Token]) raise {
  match tokens {
    More(OrOrTok, tail=rest1) => {
      let (right, rest2) = parse_and_expr(rest1)
      parse_or_tail(Binary(Or, left, right), rest2)
    }
    More(OrWordTok, tail=rest1) => {
      let (right, rest2) = parse_and_expr(rest1)
      parse_or_tail(Binary(Or, left, right), rest2)
    }
    _ => (left, tokens)
  }
}

///|
fn parse_and_expr(
  tokens : @list.List[Token],
) -> (Expr, @list.List[Token]) raise {
  let (left, rest) = parse_eq_expr(tokens)
  parse_and_tail(left, rest)
}

///|
fn parse_and_tail(
  left : Expr,
  tokens : @list.List[Token],
) -> (Expr, @list.List[Token]) raise {
  match tokens {
    More(AndAndTok, tail=rest1) => {
      let (right, rest2) = parse_eq_expr(rest1)
      parse_and_tail(Binary(And, left, right), rest2)
    }
    More(AndWordTok, tail=rest1) => {
      let (right, rest2) = parse_eq_expr(rest1)
      parse_and_tail(Binary(And, left, right), rest2)
    }
    _ => (left, tokens)
  }
}

///|
fn parse_eq_expr(tokens : @list.List[Token]) -> (Expr, @list.List[Token]) raise {
  let (left, rest) = parse_cmp_expr(tokens)
  parse_eq_tail(left, rest)
}

///|
fn parse_eq_tail(
  left : Expr,
  tokens : @list.List[Token],
) -> (Expr, @list.List[Token]) raise {
  match tokens {
    More(EqEqTok, tail=rest1) => {
      let (right, rest2) = parse_cmp_expr(rest1)
      parse_eq_tail(Binary(Eq, left, right), rest2)
    }
    _ => (left, tokens)
  }
}

///|
fn parse_cmp_expr(
  tokens : @list.List[Token],
) -> (Expr, @list.List[Token]) raise {
  let (left, rest) = parse_add_expr(tokens)
  parse_cmp_tail(left, rest)
}

///|
fn parse_cmp_tail(
  left : Expr,
  tokens : @list.List[Token],
) -> (Expr, @list.List[Token]) raise {
  match tokens {
    More(LtTok, tail=rest1) => {
      let (right, rest2) = parse_add_expr(rest1)
      parse_cmp_tail(Binary(Lt, left, right), rest2)
    }
    More(GtTok, tail=rest1) => {
      let (right, rest2) = parse_add_expr(rest1)
      parse_cmp_tail(Binary(Gt, left, right), rest2)
    }
    _ => (left, tokens)
  }
}

///|
fn parse_add_expr(
  tokens : @list.List[Token],
) -> (Expr, @list.List[Token]) raise {
  let (left, rest) = parse_mul_expr(tokens)
  parse_add_tail(left, rest)
}

///|
fn parse_add_tail(
  left : Expr,
  tokens : @list.List[Token],
) -> (Expr, @list.List[Token]) raise {
  match tokens {
    More(PlusTok, tail=rest1) => {
      let (right, rest2) = parse_mul_expr(rest1)
      parse_add_tail(Binary(Add, left, right), rest2)
    }
    More(MinusTok, tail=rest1) => {
      let (right, rest2) = parse_mul_expr(rest1)
      parse_add_tail(Binary(Sub, left, right), rest2)
    }
    _ => (left, tokens)
  }
}

///|
fn parse_mul_expr(
  tokens : @list.List[Token],
) -> (Expr, @list.List[Token]) raise {
  let (left, rest) = parse_unary_expr(tokens)
  parse_mul_tail(left, rest)
}

///|
fn parse_mul_tail(
  left : Expr,
  tokens : @list.List[Token],
) -> (Expr, @list.List[Token]) raise {
  match tokens {
    More(StarTok, tail=rest1) => {
      let (right, rest2) = parse_unary_expr(rest1)
      parse_mul_tail(Binary(Mul, left, right), rest2)
    }
    More(SlashTok, tail=rest1) => {
      let (right, rest2) = parse_unary_expr(rest1)
      parse_mul_tail(Binary(Div, left, right), rest2)
    }
    _ => (left, tokens)
  }
}

///|
fn parse_unary_expr(
  tokens : @list.List[Token],
) -> (Expr, @list.List[Token]) raise {
  match tokens {
    More(MinusTok, tail=rest) => {
      let (expr, rest2) = parse_unary_expr(rest)
      (Unary(Neg, expr), rest2)
    }
    More(NotTok, tail=rest) => {
      let (expr, rest2) = parse_unary_expr(rest)
      (Unary(Not, expr), rest2)
    }
    _ => parse_call_expr(tokens)
  }
}

///|
fn parse_call_expr(
  tokens : @list.List[Token],
) -> (Expr, @list.List[Token]) raise {
  let (callee, rest) = parse_primary_expr(tokens)
  parse_call_tail(callee, rest)
}

///|
fn parse_call_tail(
  callee : Expr,
  tokens : @list.List[Token],
) -> (Expr, @list.List[Token]) raise {
  match tokens {
    More(LParenTok, tail=rest1) => {
      let (args, rest2) = parse_args(rest1)
      parse_call_tail(Call(callee, args), rest2)
    }
    _ => (callee, tokens)
  }
}

///|
fn parse_args(
  tokens : @list.List[Token],
) -> (@list.List[Expr], @list.List[Token]) raise {
  match tokens {
    More(RParenTok, tail=rest) => (@list.empty(), rest)
    _ => {
      let (args_rev, rest) = parse_args_nonempty(tokens, @list.empty())
      (reverse_exprs(args_rev), rest)
    }
  }
}

///|
fn parse_args_nonempty(
  tokens : @list.List[Token],
  acc : @list.List[Expr],
) -> (@list.List[Expr], @list.List[Token]) raise {
  let (arg, rest1) = parse_expr(tokens)
  match rest1 {
    More(CommaTok, tail=rest2) =>
      parse_args_nonempty(rest2, @list.cons(arg, acc))
    More(RParenTok, tail=rest2) => (@list.cons(arg, acc), rest2)
    More(tok, tail=_) =>
      raise SyntaxError("unexpected token in args: " + token_name(tok))
    @list.Empty => raise SyntaxError("unexpected end in args")
  }
}

///|
fn parse_primary_expr(
  tokens : @list.List[Token],
) -> (Expr, @list.List[Token]) raise {
  match tokens {
    More(IntTok(v), tail=rest) => (IntLit(v), rest)
    More(StrTok(v), tail=rest) => (StringLit(v), rest)
    More(TrueTok, tail=rest) => (BoolLit(true), rest)
    More(FalseTok, tail=rest) => (BoolLit(false), rest)
    More(NilTok, tail=rest) => (NilLit, rest)
    More(IdentTok(name), tail=rest) => (Var(name), rest)
    More(LParenTok, tail=rest1) => {
      let (expr, rest2) = parse_expr(rest1)
      match rest2 {
        More(RParenTok, tail=rest3) => (expr, rest3)
        More(tok, tail=_) =>
          raise SyntaxError("expected ')', found: " + token_name(tok))
        @list.Empty => raise SyntaxError("expected ')' but found end")
      }
    }
    More(tok, tail=_) =>
      raise SyntaxError("unexpected token: " + token_name(tok))
    @list.Empty => raise SyntaxError("unexpected end")
  }
}
