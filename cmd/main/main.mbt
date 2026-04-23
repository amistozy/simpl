///|
/// Entry point for the CLI or runnable program in this template.
/// Keep main focused; move logic into the library package.
/// Run with `moon run cmd/main` from the project root.
fn main {
  let code =
    #| let x = #Some(-1) in
    #| if x is
    #| | #Some(y) and
    #|   | y > 0 then 1
    #|   | y == 0 then 2
    #|   end
    #| else 3

  let result = try? @lib.eval_source(code)
  debug(result)
}
