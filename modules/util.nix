lib:

let
  inherit (builtins) map elem;
  inherit (lib.lists) foldl';
in rec {

  /* Type: uniqeWith :: (a -> b) -> [a] -> [a]

     Example:
       uniqueWith (x: x.name) [ { name = "foo"; age = 10; } { name = "bar"; age = 20; } { name = "foo"; age = 20; } ]
       => [ { name = "foo"; age = 10; } { name = "bar"; age = 20; } ]
  */
  uniqueWith = f:
    foldl' (acc: x: if elem (f x) (map f acc) then acc else acc ++ [ x ]) [ ];

  /* Type: elemWith :: (a -> b) -> a -> [a] -> bool

     Example:
       elemWith (x: x.name) { name = "foo"; age = 10; }  [ { name = "foo"; age = 20; } { name = "bar"; age = 30; } ]
       => true

       elemWith (x: x.age) { name = "foo"; age = 10; }  [ { name = "foo"; age = 20; } { name = "bar"; age = 30; } ]
       => false
  */
  elemWith = f: x: xs: elem (f x) (map f xs);

  /* Type: expandWith :: (a -> b) -> (a -> b -> c) -> a -> c

     Example:
       expandWith (x: x.items) (src: x: src // { item = x; }) { items = [ "foo" "bar" "baz" ]; }
       => [ { item = "foo"; items = [ ... ]; } { item = "bar"; items = [ ... ]; } { item = "baz"; items = [ ... ]; } ]
  */
  expandWith = targetSelector: generator: src:
    map (generator src) (targetSelector src);

}
