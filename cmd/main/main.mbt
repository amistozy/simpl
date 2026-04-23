///|
/// Entry point for the CLI or runnable program in this template.
/// Keep main focused; move logic into the library package.
/// Run with `moon run cmd/main` from the project root.
fn main {
  let code =
    #| let p = [1, 0] in
    #| if (p is [0, x] or p is [x, 0]) and x > 0 then
    #|   x
    #| else
    #|   42

  let result = try? @lib.eval_source(code)
  debug(result)
}
