///|
/// Entry point for the CLI or runnable program in this template.
/// Keep main focused; move logic into the library package.
/// Run with `moon run cmd/main` from the project root.
fn main raise {
  let code =
    #| let x = 42 in
    #| {x, y: 43}
  debug(@lib.eval_source(code))
}
