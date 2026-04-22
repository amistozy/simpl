///|
/// Entry point for the CLI or runnable program in this template.
/// Keep main focused; move logic into the library package.
/// Run with `moon run cmd/main` from the project root.
fn main {
  let code =
    #| let r = ref 0 in 
    #| do r := 1 in 
    #| !r

  let result = try? @lib.eval_source(code)
  debug(result)
}
