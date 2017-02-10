open Utils
module T = SketchTypes

type exec_info =
  {
    context : T.context;
    state_exprs : T.skExpr IM.t;
    index_exprs : T.skExpr IM.t;
    inputs : T.ES.t
  }

(** exec_once : simulate the application of a function body to a set of
    expressions for the state variables. The inputs are replaced by fresh
    variables. Don't forget to call init when necessary.
    @raise {e Not_found} if an elemt is missing at some stage of the
    algorithm.

    @param stv the state variable of the function, they have to have the same
    ids as the variables present in the input expressions.
    @param exprs the inital expressions of the state variable before applying
    the function.
    @param func the function that we want to apply to the expressions.
    @param index_var The set of variable composing the index, in most cases just
    a singleton
    @param index_exprs A mapping from index variables ids to the current index
    expressions for the iteration to compute.

    @return a map of variable ids in the state to the expressions resulting from
    the application of the function to the input variables expressions.
*)

val unfold : T.skExpr IM.t -> exec_info -> T.sklet-> T.skExpr IM.t * T.ES.t
val unfold_expr : exec_info -> T.skExpr -> T.skExpr * T.ES.t
val unfold_once : ?silent:bool -> exec_info -> T.sklet -> T.skExpr IM.t * T.ES.t