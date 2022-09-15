lib:

let
  inherit (builtins) map elem;
  inherit (lib.lists) foldl';
in rec {

  # Type: uniqeWith :: (a -> b) -> [a] -> [a]
  uniqueWith = f:
    foldl' (acc: x: if elem (f x) (map f acc) then acc else acc ++ [ x ]) [ ];

  # Type: elemWith :: (a -> b) -> a -> [a] -> bool
  elemWith = f: x: xs: elem (f x) (map f xs);

  /* Type: expandWith :: (a -> b) -> (a -> b -> c) -> a -> c */
  expandWith = targetSelector: generator: src:
    map (generator src) (targetSelector src);

}
