open Str
open Printf
open PpHelper

module C = Canalyst
(**
    Locally, solving sketches is done by writing to files,
    executing a compiled racket program and then retrieving the result
    in a file.
*)

let debug = ref false
let dump_sketch = ref false

let templateDir = Filename.current_dir_name^"/templates/"
let dumpDir = Filename.current_dir_name^"/dump/"

let copy_file from_filename to_filename =
  let oc = open_out to_filename in
  let ic = open_in from_filename in
  try
    while true do
      let line = input_line ic in
      output_string oc (line^"\n");
    done
  with End_of_file ->
    begin
      close_in ic;
      close_out oc
    end
let remove_in_dir dirname =
  try
    begin
      if Sys.is_directory dirname then
        begin
          let filenames = Sys.readdir dirname in
          let complete_fn =
            Array.map (fun s -> dirname^s) filenames in
          Array.iter
            (fun filename ->
              if Sys.is_directory filename then
                ()
              else
                Sys.remove filename)
            complete_fn
        end
      else
        raise (Sys_error "Not a directory name")
    end
  with
    Sys_error s ->
      eprintf "Remove_in_dir : %s" s

let line_stream_of_channel channel =
  Stream.from
    (fun _ ->
      try Some (input_line channel) with End_of_file -> None);;

let completeFile filename solution_file_name sketch =
  let oc = open_out filename in
  let process_line line =
    fprintf oc "%s\n"
      (Str.global_replace (regexp_string "%output-file%")
         solution_file_name line)
  in
  let header = open_in (templateDir^"header.rkt") in
  Stream.iter process_line (line_stream_of_channel header);
  let fmt = Format.make_formatter
    (output oc)  (fun () -> flush oc) in
  C.pp_sketch fmt sketch;
  let footer = open_in (templateDir^"footer.rkt") in
  Stream.iter process_line (line_stream_of_channel footer);
  close_out oc


let racket filename =
  Sys.command ("racket "^filename)

let compile sketch =
  let solution_tmp_file = Filename.temp_file "conSynthSol" ".rkt" in
  let sketch_tmp_file = Filename.temp_file "conSynthSketch" ".rkt" in
  completeFile sketch_tmp_file solution_tmp_file sketch;
  let errno = racket sketch_tmp_file in
  if !dump_sketch|| (errno != 0 && !debug) then
    begin
      remove_in_dir dumpDir;
      let dump_file = dumpDir^(Filename.basename sketch_tmp_file)  in
      copy_file sketch_tmp_file dump_file;
      eprintf "Dumping sketch file in %s\n" dump_file;
      ignore(Sys.command ("cat "^dump_file));
    end;
  Sys.remove sketch_tmp_file;
  if errno != 0 then
    begin
      if !debug then
        begin
          eprintf "%sError%s while running racket on sketch.\n"
            (color "red") default;
        end;
      exit 1;
    end;
  errno, solution_tmp_file

let fetch_solution filename =
  (**
     TODO : parse the solution given by racket into a set of Cil
     expressions.
  *)
  let is = line_stream_of_channel (open_in filename) in
  let process_line line =
    print_endline line
  in
  Stream.iter process_line is;
  Sys.remove filename

let compile_and_fetch sketch =
  let errno, filename = compile sketch in
  fetch_solution filename