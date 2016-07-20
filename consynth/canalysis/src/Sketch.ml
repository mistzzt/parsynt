open Utils
open Format
open Core.Std
open Utils
open SketchTypes
open SPretty
open PpHelper
open Cil2Func

module VS = VS
module SM = Map.Make (String)


let debug = ref false;;

(**
   The main entry point of the file is build_sketch :
   build a sketch from the Floop (vector of functions
   for each state variable representing the ody of the
   loop).
*)
(**
    Replacing old expressions by sketch epxressions, and putting holes
    in some places.
*)

let hole_or_exp constr e =
  match e with
  | SkHoleL -> SkHoleL
  | SkHoleR -> SkHoleR
  | _ -> constr e

let hole_or_exp2 constr e1 e2 =
  match e1, e2 with
  | SkHoleL, SkHoleL -> SkHoleL
  | SkHoleR, SkHoleR -> SkHoleR
  | _, _ -> constr e1 e2



let rec convert (cur_v : skLVar) (vs : VS.t) =
  function
  | Var vi -> SkVar vi

  (** TODO : array -> region *)
  | Array (vi, el) ->
    begin
      try
        let vi = VSOps.getVi vi.Cil.vid vs in
        SkArray (SkVar vi, List.map el ~f:(fun e -> convert cur_v vs e), None)
      with Not_found ->
        SkHoleR
    end

  | Container (e, subs) ->
     let usv = VS.inter (VSOps.sove e) vs in
     if VS.cardinal usv > 0 then
       convert_cils vs e
     else
       SkHoleR

  | FQuestion (ecil, expr1, expr2) ->
     SkHoleR

  | FRec ((i, g, u), expr) ->
     SkRec ((i, g, u), SkLetExpr [(cur_v, convert cur_v vs expr)])

  | _ -> failwith "not yet implemented"

and convert_cils ?(cur_v = SkState) (vs : VS.t) =
  function
  | Cil.Const c -> SkHoleR

  | Cil.Lval v -> skexpr_of_lval cur_v vs v

  | Cil.SizeOf t->
     let typ = symb_type_of_ciltyp t in
     SkSizeof typ

  | Cil.SizeOfE e ->
     hole_or_exp (fun x -> SkSizeofE x) (convert_cils vs e)

  | Cil.SizeOfStr s ->
     SkSizeofStr s

  | Cil.AlignOf t ->
     SkAlignof (symb_type_of_ciltyp t)

  | Cil.AlignOfE e ->
     hole_or_exp (fun x -> SkAlignofE x) (convert_cils vs e)

  | Cil.AddrOf lv ->
     SkAddrof (skexpr_of_lval cur_v vs lv)

  | Cil.AddrOfLabel stm_ref ->
     SkAddrofLabel stm_ref

  | Cil.UnOp (op, e1, t) ->
     let op' = symb_unop_of_cil op in
     SkUnop (op',convert_cils vs e1)

  | Cil.BinOp (op, e1, e2, t) ->
     let op' = symb_binop_of_cil op in
     SkBinop (op', convert_cils vs e1, convert_cils vs e2)

  | Cil.Question (c, e1, e2, t) ->
     let c' = convert_cils vs c in
     (** TODO : do something more specific with the question *)
     SkQuestion (c', convert_cils vs e1, convert_cils vs e2)

  | Cil.CastE (t, e) ->
     SkCastE (symb_type_of_ciltyp t, convert_cils vs e)
  | Cil.StartOf lv ->
     SkStartOf (skexpr_of_lval cur_v vs lv)


and skexpr_of_lval (cur_v : skLVar)
    (vs : VS.t)
    ((host, offset) : Cil.lval) =
  match convert_offset cur_v vs offset with
  | [] -> SkVar (checkOption (CilTools.get_host_var host))
  | off_list->
     let vi =
       match CilTools.get_host_var host with
       | None ->
          (fun t x -> SkApp (t, None, off_list))
       | Some vi ->
          (fun t x -> x (SkVar vi))
     in
     match Cil.typeOfLval (host,offset) with
     | Cil.TArray (t, eo, attrs) ->
        (** Maybe array length *)
        let eo' =
          match eo with
          | None -> None
          | Some e -> Some (convert_cils vs e)
        in
        vi (symb_type_of_ciltyp t) (fun x -> SkArray (x , off_list, eo'))

     | Cil.TPtr (t, attrs) ->
        vi (symb_type_of_ciltyp t) (fun x -> SkArray (x , off_list, None))
     | _ -> failwith "Bad type."



and convert_offset cur_v vs offs =
  match offs with
  | Cil.NoOffset ->
     []

  | Cil.Field (finfo, offset)->
     failwith "Not implemented yet"

  | Cil.Index (exp, offset) ->
     let sk_off = convert_offset cur_v vs offset in
     (convert_cils vs ~cur_v:cur_v exp)::sk_off


(** TODO : add the current loop index *)
and convert_letin (vs : VS.t) =
  function
    | State (vs, subs) ->
       let state =
         List.map (IM.bindings subs)
            ~f:(fun (k,e) ->
              let cur_v = SkVarinfo (VSOps.getVi k vs) in
                                    (cur_v, convert cur_v vs e))
              in
       let complete_state =
         state@(List.map
                  (VSOps.varlist
                     (VS.filter (fun v -> not (IM.mem v.Cil.vid subs)) vs))
                  ~f:(fun vi -> (SkVarinfo vi, SkVar vi)))
       in
       SkLetExpr complete_state

    | Let (v, e, cont, i, loc) ->
       let cur_v = SkVarinfo v in
       SkLetIn ([(cur_v, convert cur_v vs e)], convert_letin vs cont)

    | LetRec (igu, let_body, let_cont, loc) ->
       (** Tail position *)
       if is_empty_state let_cont then
         SkLetExpr [(SkState, SkRec (igu, convert_letin vs let_body))]
       else
         SkLetIn ([(SkState, SkRec (igu, convert_letin vs let_body))],
                  convert_letin vs let_cont)

    | LetCond (c, let_if, let_else, let_cont, loc) ->
       if is_empty_state let_cont then
         SkLetExpr [(SkState,
                     SkCond (convert_cils vs c,
                             convert_letin vs let_if,
                             convert_letin vs let_else))]
       else
          SkLetIn ( [(SkState,
                     SkCond (convert_cils vs c,
                             convert_letin vs let_if,
                             convert_letin vs let_else))],
                  convert_letin vs let_cont)
    | LetState (let_state, let_cont) ->
       SkLetIn ([(SkState, SkFun (convert_letin vs let_state))],
                convert_letin vs let_cont)


(*** MAIN ENTRY POINT ***)

let build_sketch (let_form : letin) (state : VS.t) =
  convert_letin state let_form

(******************************************************************************)

(**
    Compile the Rosette sketch.
    Rosette is using Racket, which is based on s-expresssions
    so we will be using the Sexplib library to convert types
    directly to s-expressions
*)


(** A symbolic definition defines a list of values of a given type,
    the second string in the type corresponds *)

(** Type for building the defintions list *)
type defsRec =
  { ints : string list ;
    reals : string list ;
    bools : string list ;
    vecs : (string * string) list }

(**
     Type suitable for printing s-expressions that will be used
     as Racket macros.
*)
type symbDef =
  | Integers of string list
  | Reals of string list
  | Booleans of string list
  | RoArray of string * string list
[@@deriving sexp]

let add_to_reals s defs =
  { defs with reals = s::defs.reals }

let add_to_booleans s defs =
  { defs with bools = s::defs.bools }

let add_to_integers s defs =
  { defs with ints = s::defs.ints }

let add_to_vectors ty s defs =
  let osty = ostring_of_baseSymbolicType ty in
  match osty with
  | Some sty -> { defs with vecs = (s, sty)::defs.vecs }
  | None ->
     eprintf "add_to_vectors : vector of type too complex";
    defs

let adding_function vtype =
  let symb_type = symb_type_of_ciltyp vtype in
  match symb_type with
  | Unit -> identity2
  | Integer -> add_to_integers
  | Real -> add_to_reals
  | Boolean -> add_to_booleans
  | Vector (ty, _) -> add_to_vectors ty
  | _ ->  identity2

let add_varinfo vi defs  =
  (adding_function vi.Cil.vtype) vi.Cil.vname defs

let defsRec_to_symbDefs defs_rec
    : (symbDef * symbDef * symbDef * (symbDef list) ) =
  let ro_arrays_map =
    List.fold_left
      defs_rec.vecs
      ~init:SM.empty
      ~f:(fun tmap (vname, sty) ->
        SM.update tmap sty
          (function
          | Some l -> vname::l
          | None -> [vname] ))
  in
  let ro_arrays = SM.to_alist ro_arrays_map in
  let roArrays = List.map  ro_arrays ~f:(fun (k,v) -> RoArray (k, v))
  in
  (
    Integers defs_rec.ints,
    Reals defs_rec.reals,
    Booleans defs_rec.bools,
    roArrays
  )


(** Sketch -> Rosette sketch *)

let strings_of_symbdefs1 symbdef =
  let sexpr = sexp_of_symbDef symbdef in
  string_of_sexp sexpr


let symbolic_definitions_of vars = []

let join_sketch_of sketch = []

let loop_body_of sketch = []

let assertions_of sketch = []

let synthesis_statement_of sketch = []

let rosette_sketch_of sketch =
  let symbolic_definitions = symbolic_definitions_of sketch in
  let join_sketch = join_sketch_of sketch in
  let loop_body = loop_body_of sketch in
  let additional_assertions = assertions_of sketch in
  let main_pb = synthesis_statement_of sketch in
  Stream.of_list     (symbolic_definitions@
                        join_sketch@
                        loop_body@
                        additional_assertions@
                        main_pb)
