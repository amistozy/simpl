///|
/// Entry point for the CLI or runnable program in this template.
/// Keep main focused; move logic into the library package.
/// Run with `moon run cmd/main` from the project root.
fn main {
  let code =
    #| if
    #| | 1 > 0 and 
    #|   | 2 > 1 and 3 > 2 then 42
    #|   else 41
    #| else 40

  // let result = try? @lib.eval_source(code)
  let result = try? @lib.parse(code)
  debug(result)
}
