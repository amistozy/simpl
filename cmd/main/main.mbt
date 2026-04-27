///|
fn main {
  let command = build_command()
  try command.parse() catch {
    err => println(err)
  } noraise {
    matches => run_cli(command, matches)
  }
}

///|
fn build_command() -> @argparse.Command {
  @argparse.Command(
    "simpl",
    about="simpl language interpreter",
    options=[
      @argparse.OptionArg(
        "eval",
        short='e',
        long="eval",
        about="inline source code string",
      ),
      @argparse.OptionArg(
        "file",
        short='f',
        long="file",
        about="source file path (optional, positional path is preferred)",
      ),
    ],
    flags=[
      @argparse.FlagArg(
        "parse",
        short='p',
        long="parse",
        about="parse only and print SurfaceExpr",
      ),
    ],
    positionals=[
      @argparse.PositionArg(
        "path",
        about="source file path",
        num_args=@argparse.ValueRange(lower=0, upper=1),
      ),
    ],
  )
}

///|
priv enum SourceInput {
  Source(String)
  Help
  Error(String)
}

///|
fn run_cli(command : @argparse.Command, matches : @argparse.Matches) -> Unit {
  let parse_only = flag_enabled(matches, "parse")
  match choose_source(matches) {
    Help => println(command.render_help())
    Error(message) => {
      println("error: \{message}")
      println("")
      println(command.render_help())
    }
    Source(source) =>
      if parse_only {
        run_parse_blocks(source)
      } else {
        run_eval_blocks(source)
      }
  }
}

///|
fn choose_source(matches : @argparse.Matches) -> SourceInput {
  let eval_source = option_value(matches, "eval")
  let option_file_path = option_value(matches, "file")
  let positional_file_path = positional_path(matches)

  match eval_source {
    Some(source) =>
      if option_file_path is Some(_) || positional_file_path is Some(_) {
        Error("do not combine --eval with file path input")
      } else {
        Source(source)
      }
    None =>
      match option_file_path {
        Some(path) =>
          if positional_file_path is Some(_) {
            Error("provide file path only once: positional path or --file")
          } else {
            read_source_from_file(path)
          }
        None =>
          match positional_file_path {
            Some(path) => read_source_from_file(path)
            None => Help
          }
      }
  }
}

///|
fn read_source_from_file(path : String) -> SourceInput {
  try @fs.read_file_to_string(path) catch {
    @fs.IOError(message) => Error("cannot read file '\{path}': \{message}")
  } noraise {
    source => Source(source)
  }
}

///|
fn flag_enabled(matches : @argparse.Matches, name : String) -> Bool {
  match matches.flags.get(name) {
    Some(value) => value
    None => false
  }
}

///|
fn option_value(matches : @argparse.Matches, name : String) -> String? {
  match matches.values.get(name) {
    Some(values) => first_arg_value(values)
    None => None
  }
}

///|
fn positional_path(matches : @argparse.Matches) -> String? {
  match matches.values.get("path") {
    Some(values) => if values.length() == 0 { None } else { Some(values[0]) }
    None => None
  }
}

///|
fn first_arg_value(values : Array[String]) -> String? {
  if values.length() == 0 {
    None
  } else {
    Some(values[0])
  }
}

///|
fn run_parse_blocks(source : String) -> Unit {
  run_blocks(split_source_blocks(source), 0, run_parse_single)
}

///|
fn run_eval_blocks(source : String) -> Unit {
  run_blocks(split_source_blocks(source), 0, run_eval_single)
}

///|
fn run_blocks(
  blocks : Array[String],
  i : Int,
  runner : (String) -> Unit,
) -> Unit {
  if i >= blocks.length() {
    return
  }
  runner(blocks[i])
  if i + 1 < blocks.length() {
    println("")
  }
  run_blocks(blocks, i + 1, runner)
}

///|
fn run_parse_single(source : String) -> Unit {
  try @lib.parse(source) catch {
    _ =>
      match @lib.parse_error_text(source) {
        Some(message) => println("parse error: \{message}")
        None => println("parse error")
      }
  } noraise {
    expr => println("=> \{expr}")
  }
}

///|
fn run_eval_single(source : String) -> Unit {
  try @lib.eval_source(source) catch {
    e => println(e)
  } noraise {
    value => println("=> \{value}")
  }
}

///|
fn split_source_blocks(source : String) -> Array[String] {
  if !has_block_separator(source, 0, source.length()) {
    return [source]
  }
  split_source_blocks_with_separator(source, 0, "", [])
}

///|
fn split_source_blocks_with_separator(
  source : String,
  i : Int,
  current : String,
  acc : Array[String],
) -> Array[String] {
  if i >= source.length() {
    if is_blank_block(current, 0) {
      return acc
    }
    acc.push(current)
    return acc
  }
  let line_end = scan_line_end(source, i)
  let has_newline = line_end < source.length() &&
    source.unsafe_get(line_end).unsafe_to_char() == '\n'
  let line_no_newline = source[i:line_end].to_string()
  let next_i = if has_newline { line_end + 1 } else { line_end }
  if is_block_separator_line(line_no_newline, 0, 0, false) {
    if !is_blank_block(current, 0) {
      acc.push(current)
    }
    return split_source_blocks_with_separator(source, next_i, "", acc)
  }
  let line_with_newline = if has_newline {
    source[i:next_i].to_string()
  } else {
    line_no_newline
  }
  split_source_blocks_with_separator(
    source,
    next_i,
    current + line_with_newline,
    acc,
  )
}

///|
fn has_block_separator(source : String, i : Int, end_ : Int) -> Bool {
  if i >= end_ {
    return false
  }
  let line_end = scan_line_end(source, i)
  let line_no_newline = source[i:line_end].to_string()
  if is_block_separator_line(line_no_newline, 0, 0, false) {
    return true
  }
  let next_i = if line_end < end_ &&
    source.unsafe_get(line_end).unsafe_to_char() == '\n' {
    line_end + 1
  } else {
    line_end
  }
  has_block_separator(source, next_i, end_)
}

///|
fn scan_line_end(source : String, i : Int) -> Int {
  if i >= source.length() {
    return i
  }
  if source.unsafe_get(i).unsafe_to_char() == '\n' {
    i
  } else {
    scan_line_end(source, i + 1)
  }
}

///|
fn is_block_separator_line(
  line : String,
  i : Int,
  dash_count : Int,
  has_other_char : Bool,
) -> Bool {
  if i >= line.length() {
    return !has_other_char && dash_count >= 3
  }
  let c = line.unsafe_get(i).unsafe_to_char()
  if c == '-' {
    is_block_separator_line(line, i + 1, dash_count + 1, has_other_char)
  } else if c == ' ' || c == '\t' || c == '\r' {
    is_block_separator_line(line, i + 1, dash_count, has_other_char)
  } else {
    is_block_separator_line(line, i + 1, dash_count, true)
  }
}

///|
fn is_blank_block(text : String, i : Int) -> Bool {
  if i >= text.length() {
    return true
  }
  let c = text.unsafe_get(i).unsafe_to_char()
  if c.is_ascii_whitespace() {
    is_blank_block(text, i + 1)
  } else {
    false
  }
}
