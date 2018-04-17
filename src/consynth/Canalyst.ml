(**
   This file is part of Parsynt.

    Foobar is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    Parsynt is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with Parsynt.  If not, see <http://www.gnu.org/licenses/>.
*)

open Sketch
open Format
open Utils
open Utils.PpTools
open FError
open FuncTypes
open SymbExe
open VariableDiscovery
open Loops
open Conf

module E = Errormsg
module C = Cil
(* module Cl = Cloop *)
module A = AnalyzeLoops
(* module Z3E = Z3engine *)

let debug = ref false
let verbose = ref false
(* Do not remove dead code, some of this
   dead code is useful in the examples *)
let elim_dead_code = ref false


let parseOneFile (fname : string) : C.file =
  try
    Frontc.parse fname ()
  with
    Errormsg.Error ->
    failhere __FILE__ "parseOneFile" "Error while parsing input file,\
              the filename might contain errors"



let processFile fileName =
  C.initCIL ();
  C.insertImplicitCasts := false;
  C.lineLength := 1000;
  C.warnTruncate := false;
  Cabs2cil.doCollapseCallCast := true;
  (* Some declarations are found in another file,
     like __max_integer__, true, false, ... *)
  let decl_header =
    parseOneFile (Conf.template "decl_header.h")
  in
  let cfile = Mergecil.merge [decl_header; parseOneFile fileName] "main" in
  Cfg.computeFileCFG cfile;
  if !elim_dead_code then  Deadcodeelim.dce cfile;
  Loops.debug := !debug;
  Loops.verbose := !verbose;
  process_file cfile;
  let loops = get_loops () in
  if !verbose then
    begin
      printf "Input loops@.";
      IH.iter
        (fun lid cl -> CilTools.pps cl.lstmt) loops;
    end;
  cfile,
  IH.fold
    (fun k cl m -> IM.add k cl m)
    loops
    IM.empty

(**
   Returns a tuple with :
   - list of variables ids that a read in the loop.
   - list of state variables (written)
   - the set of variables defined in the loop.
   - a triplet for the init, guard and update of the index of the loop.
   - the function representing the body of the loop.
   - a mapping from variables to constants for variables
   that have a static initialization before the loop.
*)
type figu = VS.t * (Cil2Func.letin * Cil2Func.expr * Cil2Func.letin)
type varset_info = int list * int list * VS.t
type func_info =
  {
    host_function : Cil.varinfo;
    mutable func : Cil2Func.letin;
    mutable figu : figu option;
    lid : int;
    loop_name : string;
    lvariables : variables;
    mutable reaching_consts : Cil.exp Utils.IM.t;
    mutable inner_funcs : func_info list;
  }

let rec init_func_info linfo =
  {
    host_function = linfo.lcontext.host_function;
    func = Cil2Func.empty_state ();
    figu = None;
    lid = linfo.lid;
    loop_name = Conf.inner_loop_func_name linfo.lcontext.host_function.Cil.vname
        linfo.lid;
    lvariables = linfo.lvariables;
    reaching_consts = IM.empty;
    inner_funcs = List.map init_func_info linfo.inner_loops;
  }
(**
   Sketch info type :
    - subset of read variables
    - subset of written variables,
    - set of variables in the function
    - body of the function
    - init, guard and update of the enclosing loop
    - sketch of the join.
*)
type sigu = VS.t * (fnExpr * fnExpr * fnExpr)

(**
   From cil loop bodies to intermediary function representation.
   This step only translates the control-flow of the input C program,
   the expressions will be translated later.
*)
let cil2func cfile loops =
  Cil2Func.init loops;
  let sorted_lps = A.transform_and_sort loops in
  let rec translate_loop loop =
    let finfo = init_func_info loop in
    let stmt = (loop_body loop) in
    if !verbose then
      printf "@.Identified state variables: %a@."
        VS.pvs loop.lvariables.state_vars;
    let func, figu =
      match loop.ligu with
      | Some igu ->
        Cil2Func.cil2func loop.lvariables stmt igu
      | None -> Cil2Func.empty_state (), None
    in

    finfo.reaching_consts <- loop.lcontext.reaching_constants;
    if !verbose then
      begin
        printf "@.Reaching constants:@.";
        IM.iter
          (fun k e -> printf "%s = %s@."
              (VS.find_by_id k loop.lvariables.state_vars).Cil.vname
              (CilTools.psprint80 Cil.dn_exp e)
          ) finfo.reaching_consts
      end;
    finfo.func <- func;
    finfo.figu <- figu;
    finfo.inner_funcs <- List.map translate_loop loop.inner_loops;
    if !verbose then
      let printer =
        new Cil2Func.cil2func_printer loop.lvariables
      in
      (printf "@.%s[for loop %i in %s failed]%s@."
         (color "red") loop.lid loop.lcontext.host_function.C.vname
         color_default;);
      printer#printlet func;
      printf "@.";
    else ();
    finfo
  in
  List.map translate_loop sorted_lps


(**
   From intermediary representation with contained expressions to final
   functional representation.
*)
let no_sketches = ref 0;;

let func2sketch cfile funcreps =
  let rec  transform_func func_info =
    let var_set = func_info.lvariables.all_vars in
    let state_vars = func_info.lvariables.state_vars in
    let figu =
      match func_info.figu with
      | Some f -> f
      | None -> failhere __FILE__ "func2sketch" "Bad for loop"
    in
    let s_reach_consts =
      IM.fold
        (fun vid cilc m ->
           let expect_type =
             try
               (type_of_ciltyp
                  ((VS.find_by_id vid var_set).Cil.vtype))
             with Not_found ->
               Bottom
           in
           match Sketch.Body.conv_init_expr expect_type cilc with
           | Some e -> IM.add vid e m
           | None ->
             eprintf "@.Warning : initial value %s for %s not valid.@."
               (CilTools.psprint80 Cil.dn_exp cilc)
               (VS.find_by_id vid var_set).Cil.vname;
             m)
        func_info.reaching_consts IM.empty
    in
    if !verbose then
      begin
        printf "@.Reaching constants information:@.";
        IM.iter
          (fun k c ->
             printf "Reaching constant: %s = %a@."
               (VS.find_by_id k state_vars).Cil.vname
               FPretty.pp_fnexpr c)
          s_reach_consts
      end;
    let sketch_obj =
      new Sketch.Body.sketch_builder var_set state_vars
        func_info.func figu
    in
    sketch_obj#build;
    let loop_body, sigu =
      match sketch_obj#get_sketch with
      | Some (a,b) -> a,b
      | None -> failhere __FILE__ "func2sketch" "Failed in sketch building."
    in
    let index_set, _ = sigu in
    IH.clear SketchJoin.auxiliary_variables;
    let join_body = Sketch.Join.build state_vars loop_body in
    incr no_sketches;
    create_boundary_variables index_set;
    (* Input size from reaching definitions, min_int dependencies,
       etc. *)
    let m_sizes =
      (* Scan the intial definitions of the state variables *)
      IM.fold
        (fun k i_def m_s ->
           match i_def with
           | FnConst c when c != Infnty && c != NInfnty -> IM.add k 0 m_s
           | FnConst c -> IM.add k 1 m_s
           | FnVar v ->
             (match v with
              | FnVarinfo vi -> IM.add k 0 m_s
              | FnArray (v, e) -> IM.add k (fnArray_dep_len e) m_s
              | _ -> raise Tuple_fail)
           | _ -> failhere __FILE__"func2sketch" "Unsupported intialization.")
        s_reach_consts IM.empty
    in
    let max_m_sizes = IM.fold (fun k i m -> max i m) m_sizes 0 in
    let max_m_sizes = max max_m_sizes
        (if rec_expr2 max_min_test loop_body then 1 else 0)
    in
    (if !debug then
       printf "@.Max dependency length : %i@." max_m_sizes);
    {
      id = func_info.lid;
      host_function =
        (try check_option
              (get_fun cfile func_info.host_function.Cil.vname)
        with Failure s -> (eprintf "Failure : %s@." s;
                           failhere __FILE__ "func2sketch"
                             "Failed to get host function."));
      loop_name = func_info.loop_name;
      scontext =
        { state_vars = state_vars;
          index_vars = index_set;
          used_vars = func_info.lvariables.used_vars;
          all_vars = func_info.lvariables.all_vars;
          costly_exprs = ES.empty;
        };
      min_input_size = max_m_sizes;
      uses_global_bound = sketch_obj#get_uses_global_bounds;
      loop_body = loop_body;
      join_body = join_body;
      join_solution = FnLetExpr ([]);
      init_values = IM.empty;
      func_igu = sigu;
      reaching_consts = s_reach_consts;
      inner_functions = List.map transform_func func_info.inner_funcs;
    }
  in
  List.map transform_func funcreps


(**
   Finds auxiliary variables necessary to parallelize the function.
   @param sketch_rep the problem representation.
   @return a new problem represention where the function and the variables
   have been modified.
*)
let find_new_variables sketch_rep =
  let new_sketch = discover sketch_rep in
  (** Apply some optimization to reduce the size of the function *)
  let nlb_opt = Sketch.Body.optims new_sketch.loop_body in
  let new_loop_body =
    complete_final_state new_sketch.scontext.state_vars nlb_opt
  in
  IH.copy_into VariableDiscovery.discovered_aux_alltime
    SketchJoin.auxiliary_variables;

  let join_body =
    complete_final_state new_sketch.scontext.state_vars
      (Sketch.Join.build new_sketch.scontext.state_vars nlb_opt)
  in
  {
    new_sketch with
    loop_body = new_loop_body;
    join_body = join_body;
  }

let pp_sketch solver fmt sketch_rep =
  match solver.name with
  | "Rosette" ->
    begin
      IH.copy_into VariableDiscovery.discovered_aux_alltime
        Sketch.auxiliary_vars;
      Sketch.pp_rosette_sketch fmt sketch_rep
    end
  | _ -> ()