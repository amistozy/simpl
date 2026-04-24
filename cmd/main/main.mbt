///|
/// Entry point for the CLI or runnable program in this template.
/// Keep main focused; move logic into the library package.
/// Run with `moon run cmd/main` from the project root.
fn main {
  let code =
    #| if #Some(42) is
    #| | #Some(x) and
    #|   | x > 1 and x is 2 then x
    #|   else 41
    #| else 40

  // let result = try? @lib.eval_source(code)
  let result = try? @lib.parse(code)
  debug(result)
}
