lib:

let
  inherit (builtins) map elem toString;
  inherit (lib) concatStringsSep filter;
  inherit (lib.attrsets) mapAttrs mapAttrsToList;
  inherit (lib.lists) foldl';

  concatC = concatStringsSep ",";
in
rec {

  # Type: uniqeWith :: (a -> b) -> [a] -> [a]
  uniqueWith = f:
    foldl' (acc: x: if elem (f x) (map f acc) then acc else acc ++ [ x ]) [ ];

  # Type: elemWith :: (a -> b) -> a -> [a] -> bool
  elemWith = f: x: xs: elem (f x) (map f xs);

  # Type: expandWith :: (a -> b) -> (a -> b -> c) -> a -> c
  expandWith = targetSelector: generator: src:
    map (generator src) (targetSelector src);

  # Type: a -> a -> a -> str -> a
  mergeElement = e1: e2: defaultValue: name:
    if e1 != defaultValue && e2 != defaultValue && e1 != e2 then
      throw "Conflict `${name}` value!"
    else if e1 == e2 then
      e1
    else if e1 != defaultValue then
      e1
    else
      e2;

  # Type: (a -> b) -> [a] -> str
  toLuaTableWith = f: xs: "{${concatC (map f xs)}}";

  # Type: [a] -> str
  toLuaTable = toLuaTableWith (x: x);

}
