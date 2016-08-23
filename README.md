# ConSynth

## Requirements
Most of the source files are written in [Racket 6.4](https://racket-lang.org/download/). You can install Rosette using Racket command line tools :
```$ raco pkg install rosette```
Or you can install it from source, [more information here](https://github.com/emina/rosette).

You will also need to install the project package in order to run the different tests :\\
``` $ cd consynth```\\
``` $ raco pkg install ```\\

### OCaml
C code analysis is partially done using the Cil library in Ocaml, so you will need to install Ocaml and some packages.
- Project management : oasis. \\
  ``` opam install oasis ```
- Cil ``` opam install cil ```

To set up the Makefiles, in each directory where you can find a ```_oasis``` file, run :\\
```oasis setup -setup-update dynamic``` \\
And then compile using make.

## Project
## Structure
### All libraries and executable in ```consynth```
- ```Parsy.native``` will be the main executable generated by the Makefile.
- ```src``` contains the OCaml source files for the tool.
- ```lib``` contains the source files for the holes expressions and some syntax extensions for Rosette used by the sketches generated by the OCaml tool.
- ```templates``` contains templates in Racket to used by the tool to generate the sketch.
- ```test``` contains some tests.
- ```frontc``` is outdated an contains some C code analysis in Racket.

### Examples in ```examples```
- ```examples/synthesis``` contains examples of sketches wirtten in Rosette. ```rosette-benchmarks``` contains examples where different strategies for writing the sketches and modelling variables are tested. These examples are specific to our application, finding a divide-and-conquer strategy for a given loop body.
- ```examples/algorithms``` contains explorations of algorithms in C, but these are a bit outdated and need to be refreshed. Put here all your experiments involving hand-written parallel implementations in C.

### Parsing and analyzing input C code.
The parsing and the analysis of the input code is done with the Cil library in consynth/canalysis. To run the tests, execute the makefile in the consynth/canalysis directory and run ```./Main [filename]```

### Synthesis examples with Rosette.

## Tool source files:
### In ```src``` :
- ```Canalyst``` acts as the main interface for the core of the tool, connecting the different analysis steps and providing the interfaces. Parsing, dead code elimination and temporary variable elimination is done in this file using Cil's functions.

- ```FindLoops``` processes the file and find the loops with some auxiliary information. take a look at the structure of ```Cloop.t```. The loops are extracted with auxiliary information, including the reaching definitions of the variables used/defined in the loop, the enclosing loops if existing, enclosing function. The state variables are defined at this step as the variables defined in the loop. Loops are dropped if there is condtional exits and if we cannot define the iteration as a for loop with and inital value for the index, a boolean on the index indicating when the loop stops and and update operation to the index.
- ```AnalyzeLoops``` performs adidtional analysis. This work is still in progress, we aim to put all the array access analysis in it. The output is a sorted list of the outputs of the previous module sorted according to the decreasing loop's depth in a loop-nest, and then the loop's statement id. This transformation is split into a filtering step, a sorting step and a transformation step.

- ```Cil2Func``` the loop bodies with the information are translated to a functional intermediary representation. Right-hand side Cil expressions are either translated or put into containers.

- ```SketchBody``` converts the functional representation used in the previous step to another functional representation close to Racket's and parses the contained cil expressions. The types used in the sketch are in ```SketchTypes```.
- ```SketchJoin``` converts a functional sketch body to a functional sketch with holes representing the sketch for the join.
- ```Sketch``` provides the interface to generate the sketch representation.
- ```SPretty``` is the module containing pretty printing functions for the sketch modules, along with ```Racket``` to pretty-print some racket constructs.

- ```Utils``` contains several utility function used in the project.
- ```PpHelper``` contains pretty printing helpers.
- ```VariableAnalysis``` contains some functions for variable analysis in the Cil intermediary representation.

### In ```./```:
- The main interface is ```Parsy```. It uses ```Local``` now , the sketch is solved on the local machine but we plan to develop a ```Remote``` module to be able to transfer the heavy task (the synthesis) to a server (```synth_server.rkt```, in development).
- ```Makefile``` generated by Oasis. To compile the project's OCaml executables, execute ```make``` in this directory.
