///|
/// Surface syntax AST definitions
enum SurfaceExpr {
  SLocated(SourceSpan, SurfaceExpr)
  SIntLit(Int)
  SBoolLit(Bool)
  SStringLit(String)
  SNilLit
  SUnderscore
  SList(Array[SurfaceListItem])
  SVar(String)
  SRecord(Array[SurfaceRecordField])
  SVariant(String, SurfaceExpr)
  SIf(Array[SurfaceIfCondArm], SurfaceExpr)
  SLet(SurfacePattern, SurfaceExpr, SurfaceExpr)
  SLetAnd(Array[(SurfacePattern, SurfaceExpr)], SurfaceExpr)
  SDo(SurfaceExpr, SurfaceExpr)
  SProbe(SurfaceExpr, SurfaceExpr)
  SGuard(SurfaceGuardCondArm, SurfaceExpr?, SurfaceExpr)
  SLetFun(String, Array[SurfaceParam], SurfaceExpr, SurfaceExpr)
  SLetRec(String, Array[SurfaceParam], SurfaceExpr, SurfaceExpr)
  SLetRecAnd(Array[(String, Array[SurfaceParam], SurfaceExpr)], SurfaceExpr)
  SWith(Array[SurfaceParam], SurfaceExpr, SurfaceExpr)
  SLambda(Array[SurfaceParam], SurfaceExpr)
  SFnEta(SurfaceExpr)
  SCall(SurfaceExpr, Array[SurfaceCallArg])
  SField(SurfaceExpr, String)
  SUnary(UnOp, SurfaceExpr)
  SBinary(BinOp, SurfaceExpr, SurfaceExpr)
} derive(Debug)

///|
priv enum SurfaceParam {
  SParam(SurfacePattern, SurfaceExpr?)
} derive(Debug)

///|
priv enum SurfaceCallArg {
  SArgPos(SurfaceExpr)
  SArgNamed(String, SurfaceExpr)
  STrailingArgPos(SurfaceExpr)
} derive(Debug)

///|
priv enum SurfaceListItem {
  SListOne(SurfaceExpr)
  SListSpread(SurfaceExpr)
} derive(Debug)

///|
priv enum SurfaceIfCondArm {
  SIfCondArm(SurfaceExpr, SurfaceIfGuard)
} derive(Debug)

///|
priv enum SurfaceIfPatternArm {
  SIfPatternArm(SurfacePattern, SurfaceIfGuard)
} derive(Debug)

///|
priv enum SurfaceGuardCondArm {
  SGuardCondArm(SurfaceExpr, SurfaceGuardGuard)
} derive(Debug)

///|
priv enum SurfaceGuardPatternArm {
  SGuardPatternArm(SurfacePattern, SurfaceGuardGuard)
} derive(Debug)

///|
priv enum SurfaceGuardGuard {
  SGuardPass
  SGuardAnd(SurfaceGuardCondArm)
  SGuardIs(SurfaceExpr, SurfaceGuardPatternArm)
} derive(Debug)

///|
priv enum SurfaceIfGuard {
  SIfThen(SurfaceExpr)
  SIfAnd(Array[SurfaceIfCondArm])
  SIfIs(SurfaceExpr, Array[SurfaceIfPatternArm])
} derive(Debug)

///|
priv enum SurfaceRecordField {
  SRecordField(String, SurfaceExpr)
  SRecordShorthand(String)
} derive(Debug)

///|
priv enum SurfacePattern {
  SPBind(String)
  SPInt(Int)
  SPBool(Bool)
  SPString(String)
  SPNil
  SPAs(SurfacePattern, String)
  SPOr(Array[SurfacePattern])
  SPVariant(String, SurfacePattern)
  SPList(Array[SurfacePattern])
  SPListRest(Array[SurfacePattern], String, Array[SurfacePattern])
  SPRecord(Array[SurfaceRecordPatternField])
} derive(Debug)

///|
priv enum SurfaceRecordPatternField {
  SPRecordField(String, SurfacePattern)
  SPRecordShorthand(String)
} derive(Debug)

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
  BOpAnd
  BOpOr
  BOpRefUpdateAnd
  BOpRefUpdateOr
  BRecord
  BVariant
} derive(Debug)

///|
pub impl Show for SurfaceExpr with output(self : SurfaceExpr, logger : &Logger) -> Unit {
  logger.write_string(surface_expr_pretty(self))
}

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
