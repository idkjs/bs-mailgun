let id = (a) => a;

let const = (a, _) => a;

let flip = (f, x, y) => f(y, x);

let compose = (f, g, x) => f(g(x));

let (>>>) = (f, g, x) => f(g(x));

let (<<<) = (g, f, x) => g(f(x));
