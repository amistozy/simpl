///|
/// Entry point for the CLI or runnable program in this template.
/// Keep main focused; move logic into the library package.
/// Run with `moon run cmd/main` from the project root.
fn main {
  let code =
    #| let f(x) = #Some(x + 1) in
    #| match [1, 2] with
    #| | [x, ..] if f(x) is #Some(y) -> y
    #| | _ -> 0

  let result = try? @lib.eval_source(code)
  debug(result)
}
