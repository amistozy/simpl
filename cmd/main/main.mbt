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
priv enum SourceBlock {
  SourceBlock(String, Int)
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

  if eval_source is Some(source) {
    guard option_file_path is None && positional_file_path is None else {
      return Error("do not combine --eval with file path input")
    }
    return Source(source)
  }
  if option_file_path is Some(path) {
    guard positional_file_path is None else {
      return Error("provide file path only once: positional path or --file")
    }
    return read_source_from_file(path)
  }
  guard positional_file_path is Some(path) else { return Help }
  read_source_from_file(path)
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
  guard matches.flags.get(name) is Some(value) else { false }
  value
}

///|
fn option_value(matches : @argparse.Matches, name : String) -> String? {
  guard matches.values.get(name) is Some(values) else { None }
  first_arg_value(values)
}

///|
fn positional_path(matches : @argparse.Matches) -> String? {
  guard matches.values.get("path") is Some(values) else { None }
  guard values.length() > 0 else { None }
  Some(values[0])
}

///|
fn first_arg_value(values : Array[String]) -> String? {
  guard values.length() > 0 else { None }
  Some(values[0])
}

///|
fn run_parse_blocks(source : String) -> Unit {
  source |> split_source_blocks |> run_blocks(run_parse_single)
}

///|
fn run_eval_blocks(source : String) -> Unit {
  source |> split_source_blocks |> run_blocks(run_eval_single)
}

///|
fn run_blocks(
  blocks : Array[SourceBlock],
  runner : (String) -> Unit raise,
) -> Unit {
  for block in blocks {
    let SourceBlock(source, line_offset) = block
    runner(source) catch {
      e => println(@lib.format_error(e, line_offset))
    }
    println("")
  }
}

///|
fn run_parse_single(source : String) -> Unit raise {
  let expr = @lib.parse(source)
  println("=> \{expr}")
}

///|
fn run_eval_single(source : String) -> Unit raise {
  let value = @lib.eval_source(source)
  if should_hide_eval_result(value) {
    println("=>")
  } else {
    println("=> \{value}")
  }
}

///|
fn should_hide_eval_result(value : @lib.Value) -> Bool {
  @lib.value_is_nil_or_nil_only_list(value)
}

///|
fn split_source_blocks(source : String) -> Array[SourceBlock] {
  guard has_block_separator(source, 0, source.length()) else {
    [SourceBlock(source, 0)]
  }
  split_source_blocks_with_separator(source, 0, "", [], 1, 1)
}

///|
fn split_source_blocks_with_separator(
  source : String,
  i : Int,
  current : String,
  acc : Array[SourceBlock],
  line_no : Int,
  block_start_line : Int,
) -> Array[SourceBlock] {
  guard i < source.length() else {
    if !is_blank_block(current, 0) {
      acc.push(SourceBlock(current, block_start_line - 1))
    }
    acc
  }
  let line_end = scan_line_end(source, i)
  let has_newline = line_end < source.length() &&
    source.unsafe_get(line_end).unsafe_to_char() == '\n'
  let line_no_newline = source[i:line_end]
  let next_i = if has_newline { line_end + 1 } else { line_end }
  if is_block_separator_line(line_no_newline, 0, 0, false) {
    if !is_blank_block(current, 0) {
      acc.push(SourceBlock(current, block_start_line - 1))
    }
    return split_source_blocks_with_separator(
      source,
      next_i,
      "",
      acc,
      line_no + 1,
      line_no + 1,
    )
  }
  let line_with_newline = if has_newline {
    source[i:next_i]
  } else {
    line_no_newline
  }
  split_source_blocks_with_separator(
    source,
    next_i,
    current + line_with_newline.to_owned(),
    acc,
    line_no + 1,
    block_start_line,
  )
}

///|
fn has_block_separator(source : String, i : Int, end_ : Int) -> Bool {
  if i >= end_ {
    return false
  }
  let line_end = scan_line_end(source, i)
  let line_no_newline = source[i:line_end]
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
  line : StringView,
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
