///|
fn initial_env() -> Env {
  let env = builtin_bindings().fold(init=@hashmap.new(), (env, binding) => {
    let (name, builtin) = binding
    env.add(name, VBuiltin(builtin))
  })
  singleton_bindings().fold(init=env, (env, binding) => {
    let (name, value) = binding
    env.add(name, value)
  })
}

///|
fn builtin_bindings() -> Array[(String, Builtin)] {
  builtin_entries().map(entry => {
    let (builtin, name, _) = entry
    (name, builtin)
  })
}

///|
fn singleton_bindings() -> Array[(String, Value)] {
  [("__true", VBool(true)), ("__false", VBool(false)), ("__nil", VNil)]
}

///|
fn lookup(env : Env, name : String) -> Value raise {
  guard env.get(name) is Some(value) else { undefined_variable_error(name) }
  value
}

///|
fn lookup_function(env : Env, name : String) -> Value? {
  guard env.get(name) is Some(value) else { None }
  if value_is_function(value) {
    Some(value)
  } else {
    None
  }
}

///|
fn build_rec_env(
  defs : Array[(String, Array[Param], Expr)],
  closure_env : Env,
) -> Env {
  defs.fold(init=closure_env, (env, def) => {
    let (name, _, _) = def
    let closure = rec_closure_def(def, closure_env, defs)
    env.add(name, closure)
  })
}

///|
fn rec_closure_def(
  def : (String, Array[Param], Expr),
  closure_env : Env,
  defs : Array[(String, Array[Param], Expr)],
) -> Value {
  let (name, params, body) = def
  VRecClosure(name, params, body, closure_env, defs)
}
