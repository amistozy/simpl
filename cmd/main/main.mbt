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
            Some(message) => println(message)
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
