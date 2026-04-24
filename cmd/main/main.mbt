///|
/// Entry point for the CLI or runnable program in this template.
/// Keep main focused; move logic into the library package.
/// Run with `moon run cmd/main` from the project root.
fn main {
  let code =
    #| if
    #| | true and #Some(42) is #Some(y) and y is 0 and y > 42 and 
    #|   | y > 42 then 1
    #|   | y == 42 then 2
    #|   or
    #| else 4

  let result = try? @lib.eval_source(code)
  // let result = try? @lib.parse(code)
  debug(result)
}
