let id: 'a => 'a;

let const: ('a, _) => 'a;

let flip: (('a, 'b) => 'c, 'b, 'a) => 'c;

let compose: ('a => 'b, 'c => 'a, 'c) => 'b;

let (>>>): ('a => 'b, 'c => 'a, 'c) => 'b;

let (<<<): ('a => 'b, 'c => 'a, 'c) => 'b;
