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
  guard i < source.length() else {  }
  let c = source.unsafe_get(i).unsafe_to_char()
  if c.is_ascii_whitespace() {
    let next = advance_position(source, i, line, column)
    let (next_line, next_column) = next
    return lex_loop(source, i + 1, next_line, next_column, acc)
  }
  if c.is_ascii_digit() {
    let end = scan_digits(source, i)
    let num_text = source[i:end]
    let value = parse_digits_to_int(num_text, 0, 0)
    let span = make_span(source, i, end, line, column)
    acc.push((IntTok(value), span))
    let (_, end_pos) = span
    let (_, next_line, next_column) = end_pos
    return lex_loop(source, end, next_line, next_column, acc)
  }
  if is_ident_start(c) {
    let end = scan_ident(source, i)
    let text = source[i:end]
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
        source.unsafe_get(i + 1).unsafe_to_char() == '-' {
        skip_line_comment(source, i, line, column, acc)
      } else if i + 1 < source.length() &&
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
      } else if i + 1 < source.length() &&
        source.unsafe_get(i + 1).unsafe_to_char().is_ascii_digit() {
        let end = scan_digits(source, i + 1)
        let num_text = source[i + 1:end]
        let value = -parse_digits_to_int(num_text, 0, 0)
        let span = make_span(source, i, end, line, column)
        acc.push((IntTok(value), span))
        let (_, end_pos) = span
        let (_, next_line, next_column) = end_pos
        lex_loop(source, end, next_line, next_column, acc)
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
    '^' =>
      if i + 1 < source.length() &&
        source.unsafe_get(i + 1).unsafe_to_char() == '=' {
        push_multi_char_token(
          source,
          i,
          i + 2,
          line,
          column,
          CaretAssignTok,
          acc,
        )
      } else {
        push_single_char_token(source, i, line, column, CaretTok, acc)
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
        } else if n == '>' {
          push_multi_char_token(
            source,
            i,
            i + 2,
            line,
            column,
            FatArrowTok,
            acc,
          )
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
        push_single_char_token(source, i, line, column, ColonTok, acc)
      }
    '~' => push_single_char_token(source, i, line, column, TildeTok, acc)
    '!' =>
      if i + 1 < source.length() &&
        source.unsafe_get(i + 1).unsafe_to_char() == '=' {
        push_multi_char_token(source, i, i + 2, line, column, BangEqTok, acc)
      } else {
        push_single_char_token(source, i, line, column, BangTok, acc)
      }
    '$' => push_single_char_token(source, i, line, column, DollarTok, acc)
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
fn skip_line_comment(
  source : String,
  i : Int,
  line : Int,
  column : Int,
  acc : Array[SpannedToken],
) -> Unit raise {
  let end = scan_line_comment_end(source, i + 2)
  let (_, next_line, next_column) = advance_position_range(
    source,
    i,
    end,
    (i, line, column),
  )
  lex_loop(source, end, next_line, next_column, acc)
}

///|
fn scan_line_comment_end(source : String, i : Int) -> Int {
  guard i < source.length() else { i }
  if source.unsafe_get(i).unsafe_to_char() == '\n' {
    i
  } else {
    scan_line_comment_end(source, i + 1)
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
fn scan_digits(source : String, i : Int) -> Int {
  guard i < source.length() else { i }
  let c = source.unsafe_get(i).unsafe_to_char()
  if c.is_ascii_digit() {
    scan_digits(source, i + 1)
  } else {
    i
  }
}

///|
fn scan_ident(source : String, i : Int) -> Int {
  guard i < source.length() else { i }
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
  guard i < source.length() else {
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
  guard i + 1 < source.length() else {
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
fn parse_digits_to_int(text : StringView, i : Int, acc : Int) -> Int {
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
fn keyword_or_ident(text : StringView) -> Token {
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
    "do" => DoTok
    "guard" => GuardTok
    "with" => WithTok
    "end" => EndKeywordTok
    "is" => IsTok
    "as" => AsTok
    "and" => AndWordTok
    "or" => OrWordTok
    _ => IdentTok(text.to_owned())
  }
}
