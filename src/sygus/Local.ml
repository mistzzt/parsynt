(**
   This file is part of Parsynt.

   Author: Victor Nicolet <victorn@cs.toronto.edu>

    Parsynt is free software: you can redistribute it and/or modify
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

open Str
open Printf
open Utils

open Config
(**
    Locally, solving sketches is done by writing to files,
    executing a compiled racket program and then retrieving the result
    in a file.
*)

let debug = ref false

let dump_sketch = ref false

let dumpDir = Filename.concat project_dir "dump/"

let copy_file from_filename to_filename =
  let oc = open_out to_filename in
  let ic = open_in from_filename in
  try
    while true do
      let line = input_line ic in
      output_string oc (line ^ "\n")
    done
  with End_of_file ->
    close_in ic;
    close_out oc

let remove_in_dir dirname =
  try
    if Sys.is_directory dirname then
      let filenames = Sys.readdir dirname in
      let complete_fn = Array.map (fun s -> dirname ^ s) filenames in
      Array.iter
        (fun filename -> if Sys.is_directory filename then () else ())
        complete_fn
    else raise (Sys_error "Not a directory name")
  with Sys_error s -> eprintf "Remove_in_dir : %s" s

let line_stream_of_channel channel =
  Stream.from (fun _ -> try Some (input_line channel) with End_of_file -> None)

let completeFile filename solution_file_name sketch_printer sketch =
  let oc = Stdio.Out_channel.create filename in
  let process_line line =
    fprintf oc "%s\n" (Str.global_replace (regexp_string "%output-file%") solution_file_name line)
  in
  let header = open_in (template "header.rkt") in
  Stream.iter process_line (line_stream_of_channel header);
  let fmt = Format.formatter_of_out_channel oc in
  sketch_printer fmt sketch;
  let footer = open_in (template "footer.rkt") in
  Stream.iter process_line (line_stream_of_channel footer);
  close_out oc

let default_error i = eprintf "Errno %i : Error while running racket on sketch.\n" i

let exec_solver (timeout : int) (solver : solver) (filename : string) : int * float =
  let start = Unix.gettimeofday () in
  (* Execute on filename. *)
  let errcode =
    match solver.name with
    | "Rosette" -> Sys.command (Racket.silent_racket_command_string timeout filename)
    | "CVC4" -> Sys.command (Racket.silent_racket_command_string timeout filename)
    | _ -> Sys.command (Racket.silent_racket_command_string timeout filename)
  in
  let elapsed = Unix.gettimeofday () -. start in
  if !debug then Format.printf "@.%s : executed in %.3f s@." solver.name elapsed;
  (errcode, elapsed)

let compile ?(solver = rosette) ?(print_err_msg = default_error) (timeout : int)
    (printer : Format.formatter -> 'a -> 'b) (printer_arg : 'a) : bool * float * string =
  let solution_tmp_file = Filename.temp_file "parsynt_solution_" solver.extension in
  let sketch_tmp_file = Filename.temp_file "parsynt_sketch_" solver.extension in
  completeFile sketch_tmp_file solution_tmp_file printer printer_arg;
  (* Consider a break in the solver execution as a timeout. Thsi enables the user to
     terminate a call that is lasting too long and thus allows to 'continue' with
     the different steps of the algorithm.
  *)
  let errno, elapsed =
    try exec_solver timeout solver sketch_tmp_file with Sys.Break -> (124, -1.0)
  in
  if !dump_sketch || (errno != 0 && !debug) then (
    remove_in_dir dumpDir;
    let dump_file = dumpDir ^ Filename.basename sketch_tmp_file in
    copy_file sketch_tmp_file dump_file;
    Log.error_msg (Fmt.str "Dumping sketch file in %s\n" dump_file));
  (* Continue: signal that algorithm should continue without solution. *)
  let continue =
    if errno != 0 then
      if errno = 124 || errno = 255 then (
        Log.info_msg "Solver terminated / stopped by user.";
        true)
      else (
        Log.error_msg (Fmt.str "[ERROR] Errno : %i@." errno);
        if !debug then print_err_msg errno;
        (* ignore(Sys.command ("cat "^sketch_tmp_file)); *)
        exit 1)
    else false
  in
  (continue, elapsed, solution_tmp_file)

let fetch_solution ?(solver = rosette) filename =
  match solver.name with
  | "Rosette" ->
      let parsed =
        try
          let inf = Stdio.In_channel.create filename in
          Racket.parse_scm (Stdio.In_channel.input_all inf)
        with e -> (
          let err_code = Sys.command ("cat " ^ filename) in
          Log.error_msg Fmt.(str "cat %s : %i" filename err_code);
          match e with
          | Rparser.Error -> raise e
          | Rlexer.LexError s ->
              Log.error_msg s;
              raise e
          | e ->
              eprintf "Failure while parsing %s with simplify_parse_scm.@." filename;
              raise e)
      in
      parsed
  (* TODO *)
  | "CVC4" -> [ RAst.Int_e (-1) ]
  | _ -> [ RAst.Int_e (-1) ]

let compile_and_fetch ?(timeout = -1) ?(print_err_msg = default_error) (solver : solver)
    (printer : Format.formatter -> 'a -> 'b) (printer_arg : 'a) =
  let continue, elapsed, filename = compile ~solver ~print_err_msg timeout printer printer_arg in
  if continue then (-1.0, []) else (elapsed, fetch_solution filename)
