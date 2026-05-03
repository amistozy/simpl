///|
/// Dynamic runtime values + environment model
enum Value {
  VInt(Int)
  VBool(Bool)
  VString(String)
  VNil
  VList(Array[Value])
  VRecord(@hashmap.HashMap[String, Value])
  VVariant(String, Value)
  VRef(mut value~ : Value)
  VClosure(Array[Param], Expr, Env)
  VRecClosure(
    String,
    Array[Param],
    Expr,
    Env,
    Array[(String, Array[Param], Expr)]
  )
  VBuiltin(Builtin)
} derive(Debug)

///|
type Env = @hashmap.HashMap[String, Value]

///|
priv enum Builtin {
  BRef
  BSay
  BMap
  BFilter
  BFold
  BLength
  BReverse
  BMax
  BMin
  BSum
  BOpAdd
  BOpSub
  BOpMul
  BOpDiv
  BOpMod
  BOpPow
  BOpEq
  BOpNe
  BOpLt
  BOpLe
  BOpGt
  BOpGe
  BOpNeg
  BOpBang
  BOpDollar
  BOpRefSet
  BOpRefUpdateAdd
  BOpRefUpdateSub
  BOpRefUpdateMul
  BOpRefUpdateDiv
  BOpRefUpdateMod
  BOpRefUpdatePow
  BOpAnd
  BOpOr
  BOpRefUpdateAnd
  BOpRefUpdateOr
  BRecord
  BVariant
} derive(Debug, Eq)

///|
pub impl Show for Value with output(self : Value, logger : &Logger) -> Unit {
  logger.write_string(value_pretty(self, 6))
}

///|
impl Eq for Value with equal(a : Value, b : Value) -> Bool {
  match (a, b) {
    (VInt(x), VInt(y)) => x == y
    (VBool(x), VBool(y)) => x == y
    (VString(x), VString(y)) => x == y
    (VNil, VNil) => true
    (VList(x), VList(y)) => x == y
    (VRecord(x), VRecord(y)) => x == y
    (VVariant(tag1, value1), VVariant(tag2, value2)) =>
      tag1 == tag2 && value1 == value2
    _ => false
  }
}
