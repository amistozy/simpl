///|
/// Core AST definitions
priv enum Expr {
  Located(SourceSpan, Expr)
  IntLit(Int)
  StringLit(String)
  List(Array[ListItem])
  Var(String)
  If(Array[IfCondArm], Expr)
  Let(MatchPattern, Expr, Expr)
  LetAnd(Array[(MatchPattern, Expr)], Expr)
  LetRec(String, Array[Param], Expr, Expr)
  LetRecAnd(Array[(String, Array[Param], Expr)], Expr)
  Lambda(Array[Param], Expr)
  Call(Expr, Array[CallArg])
  Field(Expr, String)
} derive(Debug)

///|
priv enum Param {
  Param(MatchPattern, Expr?, String?)
} derive(Debug)

///|
priv enum CallArg {
  ArgPos(Expr)
  ArgNamed(String, Expr)
} derive(Debug)

///|
priv enum ListItem {
  ListOne(Expr)
  ListSpread(Expr)
} derive(Debug)

///|
priv enum IfCondArm {
  IfCondArm(Expr, IfGuard)
} derive(Debug)

///|
priv enum IfPatternArm {
  IfPatternArm(MatchPattern, IfGuard)
} derive(Debug)

///|
priv enum IfGuard {
  IfThen(Expr)
  IfAnd(Array[IfCondArm])
  IfIs(Expr, Array[IfPatternArm])
} derive(Debug)

///|
priv enum MatchPattern {
  PBind(String)
  PInt(Int)
  PBool(Bool)
  PString(String)
  PNil
  PAs(MatchPattern, String)
  POr(Array[MatchPattern])
  PVariant(String, MatchPattern)
  PList(Array[MatchPattern])
  PListRest(Array[MatchPattern], String, Array[MatchPattern])
  PRecord(Array[(String, MatchPattern)])
} derive(Debug)

///|
priv enum BinOp {
  Add
  Sub
  Mul
  Div
  Mod
  Pow
  Eq
  Ne
  Lt
  Le
  Gt
  Ge
  And
  Or
  RefSet
  RefUpdateAdd
  RefUpdateSub
  RefUpdateMul
  RefUpdateDiv
  RefUpdateMod
  RefUpdateAnd
  RefUpdateOr
} derive(Debug)

///|
priv enum UnOp {
  Neg
  Bang
  Dollar
} derive(Debug)
