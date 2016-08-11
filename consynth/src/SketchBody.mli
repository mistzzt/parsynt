val build : Cil2Func.letin -> Utils.VS.t -> SketchTypes.sklet
val convert : SketchTypes.skLVar -> Cil2Func.expr -> SketchTypes.skExpr
val convert_const : Cil.constant -> SketchTypes.skExpr
val convert_cils :
  ?cur_v:SketchTypes.skLVar ->
  ?subs:SketchTypes.skExpr Utils.IM.t ->
  Cil.exp -> SketchTypes.skExpr
