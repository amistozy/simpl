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
pub impl Show for SurfaceExpr with output(self : SurfaceExpr, logger : &Logger) -> Unit {
  logger.write_string(surface_expr_pretty(self))
}
