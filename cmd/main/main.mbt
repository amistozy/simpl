///|
fn main {
  let command = build_command()
  try command.parse() catch {
    err => println(err.to_string())
  } noraise {
    matches => {
      let _ = run_cli(command, matches)
    }
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
        about="evaluate inline source code",
      ),
      @argparse.OptionArg(
        "file",
        short='f',
        long="file",
        about="read and evaluate source file",
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
        "code",
        about="inline source code when -e/-f are not used",
        num_args=@argparse.ValueRange(lower=0),
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
fn run_cli(command : @argparse.Command, matches : @argparse.Matches) -> Bool {
  let parse_only = flag_enabled(matches, "parse")
  match choose_source(matches) {
    Help => {
      println(command.render_help())
      true
    }
    Error(message) => {
      println("error: " + message)
      println("")
      println(command.render_help())
      false
    }
    Source(source) =>
      if parse_only {
        run_parse(source)
      } else {
        run_eval(source)
      }
  }
}

///|
fn choose_source(matches : @argparse.Matches) -> SourceInput {
  let eval_source = option_value(matches, "eval")
  let file_path = option_value(matches, "file")
  let positional_source = positional_code(matches)

  let mut source_count = 0
  if eval_source is Some(_) {
    source_count = source_count + 1
  }
  if file_path is Some(_) {
    source_count = source_count + 1
  }
  if positional_source is Some(_) {
    source_count = source_count + 1
  }

  if source_count == 0 {
    return Help
  }
  if source_count > 1 {
    return Error(
      "provide exactly one source input: --eval, --file, or positional code",
    )
  }

  match eval_source {
    Some(source) => Source(source)
    None =>
      match file_path {
        Some(path) => read_source_from_file(path)
        None =>
          match positional_source {
            Some(source) => Source(source)
            None => Help
          }
      }
  }
}

///|
fn read_source_from_file(path : String) -> SourceInput {
  try @fs.read_file_to_string(path) catch {
    @fs.IOError(message) => Error("cannot read file '" + path + "': " + message)
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
fn positional_code(matches : @argparse.Matches) -> String? {
  match matches.values.get("code") {
    Some(values) =>
      if values.length() == 0 {
        None
      } else {
        Some(join_string_array(values, 0))
      }
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
fn join_string_array(values : Array[String], i : Int) -> String {
  if i >= values.length() {
    return ""
  }
  if i + 1 >= values.length() {
    return values[i]
  }
  values[i] + " " + join_string_array(values, i + 1)
}

///|
fn run_parse(source : String) -> Bool {
  try @lib.parse(source) catch {
    _ => {
      match @lib.parse_error_text(source) {
        Some(message) => println("parse error: " + message)
        None => println("parse error")
      }
      false
    }
  } noraise {
    expr => {
      println("=> " + expr.to_string())
      true
    }
  }
}

///|
fn run_eval(source : String) -> Bool {
  try @lib.eval_source(source) catch {
    _ => {
      match @lib.parse_error_text(source) {
        Some(message) => println("parse error: " + message)
        None =>
          match @lib.eval_error_text(source) {
            Some(message) => println("runtime error: " + message)
            None => println("evaluation failed")
          }
      }
      false
    }
  } noraise {
    value => {
      println("=> " + value.to_string())
      true
    }
  }
}
