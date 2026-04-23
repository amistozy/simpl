///|
/// Entry point for the CLI or runnable program in this template.
/// Keep main focused; move logic into the library package.
/// Run with `moon run cmd/main` from the project root.
fn main {
  let code =
    #| match 41 with
    #| | 42 -> 
    #|   match 41 with
    #|   | 42 -> 0
    #|   | _ -> 1
    #|   end
    #| | _ -> 2

  let result = try? @lib.eval_source(code)
  debug(result)
}
