val id : 'a -> 'a
val const : 'a -> _ -> 'a
val flip : ('a -> 'b -> 'c) -> 'b -> 'a -> 'c
val compose : ('a -> 'b) -> ('c -> 'a) -> 'c -> 'b
val (>>>) : ('a -> 'b) -> ('c -> 'a) -> 'c -> 'b
val (<<<) : ('a -> 'b) -> ('c -> 'a) -> 'c -> 'b
