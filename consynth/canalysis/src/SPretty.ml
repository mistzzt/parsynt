open PpHelper
open SketchTypes
open Format
open Utils

module Ct = Utils.CilTools
module VS = Utils.VS

(** String representing holes *)
let current_hole_l_expression = ref "x y z"
let current_hole_r_expression = ref "x y z"
let read_only_arrays = ref VS.empty

let set_hole_vars lvs rvs =
  let l_str, r_str =
    (VSOps.pp_var_names str_formatter lvs;
    flush_str_formatter ()),
    (VSOps.pp_var_names str_formatter rvs;
    flush_str_formatter ())
  in
  current_hole_r_expression := r_str;
  current_hole_l_expression := l_str

let wrap (t : symbolic_type) ppf =
  fprintf ppf
    (match t with
    | Unit -> "(bExpr %s)"
    | Integer -> "(bExpr:int %s)"
    | Real -> "(bExpr:real %s)"
    | Boolean -> "(bExpr:boolean %s)"
    | Function (a, b) ->
       begin
         match a, b with
         | Integer, Boolean -> "(bExpr:int->bool %s)"
         | Integer, Integer -> "(bExpr:int_>int %s)"
         | _ ,_ -> "(bExpr %s)"
       end
    | _ -> "(bExpr %s)")

(** Pretty-printing operators *)

let string_of_unsafe_binop =
  function
  | TODO -> "TODO"

let string_of_symb_binop =
  function
  | And -> "and"
  | Nand -> "nand" | Or -> "or" | Nor -> "nor" | Implies -> "implies"
  | Xor -> "xor"
  (** Integers and reals *)
  | Plus -> "+" | Minus -> "-" | Times -> "*" | Div -> "/"
  | Quot -> "quot" | Rem -> "rem" | Mod -> "mod"
  (** Max and min *)
  | Max -> "max" | Min -> "min"
  (** Comparison *)
  | Eq -> "=" | Lt -> "<" | Le -> "<=" | Gt -> ">" | Ge -> ">="
  | Neq -> "neq"
  (** Shift*)
  | ShiftL -> "shiftl" | ShiftR -> "shiftr"
  | Expt -> "expt"
  | UnsafeBinop op -> string_of_unsafe_binop op

(** ********************************************************* UNARY OPERATORS *)
(**
   Some racket function that are otherwise unsafe
   to use in Racket, but we might still need them.
*)
let string_of_unsafe_unop =
  function
  (** Trigonometric + hyp. functions *)
  | Sin -> "sin" | Cos -> "cos" | Tan -> "tan" | Sinh -> "sinh"
  | Cosh -> "cosh" | Tanh -> "tanh"
  (** Anti functions *)
  | ASin -> "asin" | ACos -> "acos" | ATan -> "atan" | ASinh -> "asinh"
  | ACosh -> "acosh" | ATanh
  (** Other functions *)
  | Log -> "log" | Log2 -> "log2" | Log10 -> "log10"
  | Exp -> "exp" | Sqrt -> "sqrt"


let string_of_symb_unop =
  function
  | UnsafeUnop op -> string_of_unsafe_unop op
  | Not -> "Not" | Add1 -> "Add1" | Sub1 -> "Sub1"| Abs -> "Abs"
  | Floor -> "Floor" | Ceiling -> "Ceiling"  | Truncate -> "Truncate"
  | Round -> "Round" | Neg -> "Neg" | Sgn -> "Sgn"

let ostring_of_baseSymbolicType =
  function
  | Integer -> Some "integer?"
  | Real -> Some "real?"
  | Boolean -> Some "boolean?"
  | _ -> None

let rec pp_symb_type ppf t =
  match ostring_of_baseSymbolicType t with
  | Some s -> fprintf ppf "%s" s
  | None ->
     begin
       match t with
       | Unit -> fprintf ppf "unit"
       | Tuple tl ->
          fprintf ppf "(%a)"
            (fun ppf l ->
              pp_print_list
                ~pp_sep:(fun ppf () -> fprintf ppf ",")
                (fun ppf ty -> pp_symb_type ppf ty)
                ppf
                l)
            tl

       | Bitvector (t, i)->
          fprintf ppf "(bitvector %a %i)"
            pp_symb_type t i

       | Function (a, b)
       | Procedure (a, b) ->
          fprintf ppf "%a->%a"
            pp_symb_type a
            pp_symb_type b

       | Pair t -> fprintf ppf "(pair %a)" pp_symb_type t

       | List (t, io) ->
          begin
            match io with
            | Some i ->
               fprintf ppf "(list %a %i)"
                 pp_symb_type t i
            | None ->
               fprintf ppf "(list %a ??)"
                 pp_symb_type t
          end

       | Vector (t, io) ->
          begin
            match io with
            | Some i ->
               fprintf ppf "(vector %a %i)"
                 pp_symb_type t i
            | None ->
               fprintf ppf "(vector %a ??)"
                 pp_symb_type t
          end

       | Box t ->
          fprintf ppf "(box %a)" pp_symb_type t

       | Struct t ->
          fprintf ppf "(struct %a)" pp_symb_type t

       | _ -> ()
     end

let rec pp_constants ppf =
  function
  | CInt i -> fprintf ppf "%i" i
  | CInt64 i -> fprintf ppf "%i" (Int64.to_int i)
  | CReal f -> fprintf ppf "%10.3f" f
  | CBool b -> fprintf ppf "%b" b
  | CBox cst -> fprintf ppf "<Cil.constant>"
  | CChar c -> fprintf ppf "%c" c
  | CString s -> fprintf ppf "%s" s
  | CUnop (op, c) ->
     fprintf ppf "(%s %a)" (string_of_symb_unop op) pp_constants c
  | CBinop (op, c1, c2) ->
     fprintf ppf "(%s %a %a)" (string_of_symb_binop op)
       pp_constants c1 pp_constants c2
  | CUnsafeUnop (unsop, c) -> fprintf ppf  ""
  | CUnsafeBinop (unsbop, c1, c2) -> fprintf ppf ""
  | Pi -> fprintf ppf "pi"
  | Sqrt2 -> fprintf ppf "(sqrt 2)"
  | Ln2 -> fprintf ppf "(log 2)"
  | Ln10 -> fprintf ppf "(log 10)"
  | SqrtPi -> fprintf ppf "(sqrt pi)"
  | E -> fprintf ppf "(exp 1)"

(** Basic pretty-printing *)
let rec pp_skstmt ppf ((vi, sklet) : Cil.varinfo * sklet)  =
  Format.fprintf  ppf "%s = %sbegin%s@.@[%a@] %send%s\n"
    vi.Cil.vname
    (color "yellow") default
    pp_sklet sklet
    (color "yellow") default

and pp_sklet ppf =
  function
  | SkLetExpr el ->
     fprintf ppf "@[(state %a)@]"
       (pp_print_list
          ~pp_sep:(fun ppf () -> fprintf ppf " ")
          (fun ppf (v,e) -> pp_skexpr ppf e)) el

  | SkLetIn (el, l) ->
     fprintf ppf "(%slet%s @[<hov 2>(%a)@]@;@[<hov 2> %a@]"
       (color "red") default
       (fun ppf el ->
         (pp_print_list
            (fun ppf (v, e) ->
              Format.fprintf ppf "@[[%a %a]@]"
                pp_sklvar v pp_skexpr e) ppf el)) el
       pp_sklet l

and pp_sklvar (ppf : Format.formatter) sklvar =
  match sklvar with
  | SkState ->
	fprintf ppf "<s>"
  | SkVarinfo v ->
	fprintf ppf "%s" v.Cil.vname
  | SkArray (v, offset) ->
    match vi_of v with
    | Some vi ->
       begin
         if VS.mem vi !read_only_arrays
         then
           fprintf ppf "(%a %a)" pp_sklvar v pp_skexpr offset
         else
	       fprintf ppf "(vector-ref %a %a)" pp_sklvar v pp_skexpr offset
       end
    | None ->
       	fprintf ppf "(vector-ref %a %a)" pp_sklvar v pp_skexpr offset

and pp_skexpr (ppf : Format.formatter) skexpr =
let fp = Format.fprintf in
  match skexpr with
  | SkVar v -> fp ppf "%a" pp_sklvar v

  | SkConst c -> fp ppf "%a" pp_constants c

  | SkFun l -> pp_sklet ppf l

  | SkApp (t, vio, argl) ->
     let funname =
       match vio with
       | Some vi -> vi.Cil.vname
       | None -> "()"
     in
     fp ppf "(%s%s%s %a)" (color "yellow") funname default
       (pp_print_list pp_skexpr) argl

  | SkHoleR t -> fp ppf "%a" (wrap t) !current_hole_r_expression

  | SkHoleL (v, t) -> fp ppf "%a" (wrap t) !current_hole_l_expression

  | SkAddrof e -> fp ppf "(AddrOf )"

  | SkAddrofLabel addr -> fp ppf "(AddrOfLabel)"

  | SkAlignof typ -> fp ppf "(AlignOf typ)"

  | SkAlignofE e -> fp ppf "(AlignOfE %a)" pp_skexpr e

  | SkBinop (op, e1, e2) ->
     fp ppf "(%s %a %a)"
        (string_of_symb_binop op) pp_skexpr e1 pp_skexpr e2

  | SkUnop (op, e) ->
     fp ppf "(%s %a)" (string_of_symb_unop op) pp_skexpr e

  | SkCond (c, e1, e2) ->
     fp ppf "(%sif%s @[%a@] @[%a@] @[%a@])"
       (color "blue") default
       pp_skexpr c pp_sklet e1 pp_sklet e2

  | SkQuestion (c, e1, e2) ->
     fp ppf "(%sif%s @[%a@] @[%a@] @[%a@])"
       (color "blue") default
       pp_skexpr c pp_skexpr e1 pp_skexpr e2

  | SkRec ((i, g, u), e) ->
     fp ppf "(%sLoop%s %s %s %s %a)"
       (color "blue") default
       (Ct.psprint80 Cil.dn_instr i)
       (Ct.psprint80 Cil.dn_exp g)
       (Ct.psprint80 Cil.dn_instr u)
       pp_sklet e

  | SkSizeof t -> fp ppf "(SizeOf %a)" pp_symb_type t

  | SkSizeofE e -> fp ppf "(SizeOf %a)" pp_skexpr e

  | SkSizeofStr str -> fp ppf "(SizeOf %s)" str

  | SkCastE (t,e) ->
     fp ppf "(%a) %a" pp_symb_type t pp_skexpr e

  | SkStartOf l -> fp ppf "(StartOf %a)" pp_skexpr l


(** Print statements **)
let printSkstmt s = pp_skstmt std_formatter s
let sprintSkstmt s =
  pp_skstmt str_formatter s;
  flush_str_formatter ()

let eprintSkstmt s = pp_skstmt err_formatter s

(** Print let-forms *)
let printSklet s = pp_sklet std_formatter s
let sprintSklet s =
  pp_sklet str_formatter s;
  flush_str_formatter ()

let eprintSklet s = pp_sklet err_formatter s

(** Print epxressions *)
let printSkexpr s = pp_skexpr std_formatter s
let sprintSkexpr s =
  pp_skexpr str_formatter s;
  flush_str_formatter ()

let eprintSkexpr s = pp_skexpr err_formatter s

(** Pritn the whole intermediary sketch *)
let pp_sketch ppf (state_set, stmt_li) =
  fprintf ppf "@[State = %a@]@;@[%a@]"
    Utils.VSOps.pvs state_set
    (pp_print_list
       ~pp_sep:(fun fmt x -> fprintf fmt "\n@.")
       pp_skstmt) stmt_li

(** Print sketches *)
let printSketch s = pp_sketch std_formatter s
let sprintSketch s =
  pp_sketch str_formatter s;
  flush_str_formatter ()

let eprintSketch s = pp_sketch err_formatter s
