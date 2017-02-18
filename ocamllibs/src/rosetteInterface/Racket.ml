open Format
open RUtils
open Ast
open Utils

type racket_struct = string * (string list)

(** Functions to print Racket constructs *)

let pp_struct_defintion fmt (sname, fields) =
  fprintf fmt "@[<1>(struct %s (%a))@;@]"
    sname
    (pp_print_list
       ~pp_sep:(fun f _ -> fprintf f " ")
       (fun f s -> fprintf f "%s" s)) fields

let pp_struct_equality fmt (sname, fields) =
  fprintf fmt "(define (%s-eq? s1 s2)@;(and %a))"
    sname
    (pp_print_list
       ~pp_sep:(fun f _ -> fprintf f " ")
       (fun f s ->
          fprintf f "@[<2>(eq? (%s-%s s1) (%s-%s s2))@]@;"
            sname s sname s)) fields


let pp_assignments state_struct_name state_name fmt =
  pp_print_list
    ~pp_sep:(fun fmt () -> Format.fprintf fmt "@;")
    (fun fmt (var_name, field_name) -> Format.fprintf fmt "[%s (%s-%s %s)]"
        var_name state_struct_name field_name state_name) fmt


let pp_comment fmt str =
  Format.fprintf fmt ";;%s@." str

let pp_body_app fmt (body_name, s, from, to_n) =
  Format.fprintf fmt "@[<hov 2>(%s (%s %i %i) %i %i)@]"
    body_name s from to_n from to_n


(** 4 - Grammar macros parameters *)

type rosette_hole_type =
  | HArith
  | HNonLinear
  | HBasicNum
  | HBoolean
  | HComparison
  | HNumIte
  | HScalarExpr

let hole_type_assoc =
  [(HArith, "NumExprArith");
   (HNonLinear, "NumExprNL");
   (HBasicNum, "NumExprBasic");
   (HBoolean, "BoolExpr");
   (HComparison, "BoolExprCompar");
   (HNumIte, "NumIte");
   (HScalarExpr, "ScalarExpr")]

let hole_type_name t = List.assoc t hole_type_assoc

let hole_name_type s =
  try
    Some (fst
            (List.hd (List.filter (fun (t, s') -> s = s') hole_type_assoc)))
  with Failure s -> None

type rosette_operator_choice =
  | OCComparison
  | OCScalar
  | OCBasicNum
  | OCArith
  | OCNonLinear
  | OCBoolean
  | OCUnopsNum

let operator_choice_assoc =
  [(OCComparison, "ComparisonOps");
   (OCScalar, "ScalarOps");
   (OCBasicNum, "BasicBinopsNum");
   (OCArith, "ArithBinops");
   (OCNonLinear, "NLBinopsNum");
   (OCBoolean, "BinopsBool");
   (OCUnopsNum, "BasicUnopsNum")]

let operator_choice_name t = List.assoc t operator_choice_assoc

let operator_choice_type s =
  try
    Some (fst (List.hd
                 (List.filter (fun (t, s') -> s = s') operator_choice_assoc)))
  with Failure s -> None

let unsolved_hole (expr : Ast.expr) =
  match expr with
  (* (HoleName args hole-depth) *)
  | Apply_e (Id_e s, arglist) ->
    (match hole_name_type s with
    | Some ht -> Some ht, None
    | _ -> None, None), arglist

  (* ((OperatorChoice int) args) *)
  | Apply_e (Apply_e (Id_e s, _), arglist) ->
    (match operator_choice_type s with
    | Some oct -> None, Some oct
    | _ -> None, None), arglist
  | _ -> (None, None), []


let repl_unsolved_hole
    (e : Ast.expr)
    (hi : (rosette_hole_type option *
          rosette_operator_choice option)
          * Ast.expr list) : Ast.expr =
  match hi with
  | (Some ht, _), arglist ->
    (match ht with
     | HBoolean -> Bool_e true
     | HComparison -> Bool_e true
     | _ ->
       try List.hd arglist with _ -> Int_e 1)

  | (_, Some oct), arglist ->
    (match oct with
     | OCBoolean ->
       (try
          (if List.nth arglist 0 = List.nth arglist 1 then Bool_e true
           else Bool_e false)
        with _ -> Bool_e false)
     | _ -> e)
  | _ -> e


let rec clean (expr : Ast.expr) =
  match (repl_unsolved_hole expr (unsolved_hole expr)) with
  | Binop_e (op, e1, e2) -> Binop_e (op, clean e1, clean e2)
  | Unop_e (op, e1) -> Unop_e (op, clean e1)
  | If_e (c, e1, e2) -> If_e (clean c, clean e1, clean e2)
  | Apply_e (ef, arglist) -> Apply_e (clean ef, List.map clean arglist)
  | Let_e (ide_list, el) ->
    Let_e (List.map (fun (v, e) -> (v, clean e)) ide_list, clean el)
  | Letrec_e (ide_list, el) ->
    Letrec_e (List.map (fun (v, e) -> (v, clean e)) ide_list, clean el)
  | Def_e (il, e) -> Def_e (il, clean e)
  | Defrec_e (il, e) -> Defrec_e (il, clean e)
  | Fun_e (il, e) -> Fun_e (il, clean e)
  | e -> e


let rec partial_eval_cond e =
  let pc_t =
    { t_expr =
        (fun rfunc e ->
           match  e with
           | Binop_e (op, _e1, _e2) ->
             let e1 = rfunc _e1 in let e2 = rfunc _e2 in
             begin
             match e1, e2 with
             | e1, e2 when e1 = e2 ->
               (match op with
                  (* Boolean operators *)
                  | Eq -> Some (Bool_e true)
                  | Neq -> Some (Bool_e false)
                  | Or  | And -> Some e1
                  (* Comparisons  *)
                  | Lt | Gt -> Some (Bool_e false)
                  | Geq | Leq -> Some (Bool_e true)
                  | _ -> None)

             | Bool_e true, e' | e', Bool_e true ->
               (match op with
                | And -> Some e'
                | Or -> Some (Bool_e true)
                | Eq -> Some e'
                | _ -> None)

             | Bool_e false, e' | e', Bool_e false ->
               (match op with
                | And -> Some (Bool_e false)
                | Or -> Some e'
                | Eq -> Some e'
                | _ -> None)

             | _ -> None
             end

           | Unop_e (op, e0) ->
             let e0_ev = rfunc e0 in
             (match e0_ev with
              | Bool_e t -> Some (Bool_e (not t))
              | Id_e "??" -> Some e0_ev
              | _ -> Some e0_ev)

           | _ -> None);
      t_const = identity;
      t_id = identity;
    }
  in transform pc_t e

and partial_eval e =
  let pe_t =
    {
      t_expr =
        (fun rfunc e ->
           match e with
           | If_e (c, e1, e2) ->
             (match partial_eval_cond c with
             | Bool_e true -> Some e1
             | Bool_e false -> Some e2
             | _ -> None)
           | _ -> None);
      t_const = identity;
      t_id = identity;
    }
  in
  transform pe_t e

and partial_eval_arith e =
  let arith_t =
    {
      t_expr =
        (fun rfunc e ->
           match e with
           | Binop_e (op, e1, e2) ->
             (match rfunc e1, rfunc e2 with
             | Int_e i1, Int_e i2 ->
               Some (apply_int op i1 i2)
             | Float_e i1, Float_e i2 ->
               Some (apply_float op i1 i2)
             | Bool_e i1, Bool_e i2 ->
               Some (apply_bool op i1 i2)
             | _, _ -> None)
           | Unop_e (op, e0) -> None
           | _ -> None);
      t_id = identity;
      t_const = identity;
    }
  in
  transform arith_t e

(*** MAIN FUNCTION *)
let parse_scm s =
  List.map (clean --> partial_eval_arith --> partial_eval)
    (Parser.main Lexer.token (Lexing.from_string s))
