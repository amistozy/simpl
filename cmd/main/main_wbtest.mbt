///|
test "should_hide_eval_result keeps normal values visible" {
  let int_value = try @lib.eval_source("42") catch {
    _ => panic()
  } noraise {
    v => v
  }
  let list_value = try @lib.eval_source("[1]") catch {
    _ => panic()
  } noraise {
    v => v
  }
  assert_false(should_hide_eval_result(int_value))
  assert_false(should_hide_eval_result(list_value))
}

///|
test "should_hide_eval_result hides nil value" {
  let value = try @lib.eval_source("nil") catch {
    _ => panic()
  } noraise {
    v => v
  }
  assert_true(should_hide_eval_result(value))
}

///|
test "should_hide_eval_result hides flat nil-only list" {
  let value = try @lib.eval_source("[nil; nil]") catch {
    _ => panic()
  } noraise {
    v => v
  }
  assert_true(should_hide_eval_result(value))
}

///|
test "should_hide_eval_result hides nested nil-only list" {
  let value = try @lib.eval_source("[[nil]; [nil; [nil]]]") catch {
    _ => panic()
  } noraise {
    v => v
  }
  assert_true(should_hide_eval_result(value))
}
