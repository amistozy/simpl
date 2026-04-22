///|
/// Entry point for the CLI or runnable program in this template.
/// Keep main focused; move logic into the library package.
/// Run with `moon run cmd/main` from the project root.
fn main raise {
  let code =
    #| match {x: 10, y: 32} {
    #|   {x} => x + 1
    #| }
  debug(@lib.eval_source(code))
}
