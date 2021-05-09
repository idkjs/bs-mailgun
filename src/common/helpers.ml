let id a = a
let const a _ = a
let flip f x y = f y x
let compose f g x = f (g x)
let (>>>) f g = fun x -> f (g x)
let (<<<) g f = fun x -> g (f x)
