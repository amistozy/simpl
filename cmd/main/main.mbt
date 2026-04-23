///|
/// Entry point for the CLI or runnable program in this template.
/// Keep main focused; move logic into the library package.
/// Run with `moon run cmd/main` from the project root.
fn main {
  let code =
    #| let xs = [1, 2, 3] in
    #| xs is [x, ..] and x > 0

  let result = try? @lib.eval_source(code)
  debug(result)
}
