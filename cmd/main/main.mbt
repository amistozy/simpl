///|
/// Entry point for the CLI or runnable program in this template.
/// Keep main focused; move logic into the library package.
/// Run with `moon run cmd/main` from the project root.
fn main {
  let code =
    #| let f(x) = x += 1;
    #| let r = ref 42;
    #| do f(r);
    #| !r

  let result = try? @lib.eval_source(code)
  // let result = try? @lib.parse(code)
  debug(result)
}
