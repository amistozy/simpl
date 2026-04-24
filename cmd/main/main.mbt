///|
/// Entry point for the CLI or runnable program in this template.
/// Keep main focused; move logic into the library package.
/// Run with `moon run cmd/main` from the project root.
fn main {
  let code =
    #| if true and #Some(42) is
    #|   #Some(42) then 1
    #|   else 2
    #| end

  let result = try? @lib.eval_source(code)
  // let result = try? @lib.parse(code)
  debug(result)
}
