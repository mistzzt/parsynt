open Cil
open Inthash

module RWSet : sig
    val computeRWs: Cil.stmt list -> unit
    val getRWs: int -> int Inthash.t option
    val printRWs: int -> int Inthash.t option -> Cil.varinfo Inthash.t -> unit
    val iw : int
    val ir : int
    val irw : int
    val indef : int
end
