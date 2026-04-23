///|
/// Entry point for the CLI or runnable program in this template.
/// Keep main focused; move logic into the library package.
/// Run with `moon run cmd/main` from the project root.
fn main {
  let code =
    #| if {x: 1, y: 2} is
    #|   {x: y} then y

  let result = try? @lib.eval_source(code)
  debug(result)
}
