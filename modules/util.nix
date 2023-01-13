lib:

let
  inherit (builtins) map elem filter head;
  inherit (lib) concatStringsSep;
  inherit (lib.lists) foldl' imap1;

  # Type: [str] -> str
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

  # Type: (a -> str) -> [a] -> str
  toLuaTableWith = f: xs: "{${concatC (map f xs)}}";

  # Type: [str] -> str
  toLuaTable = toLuaTableWith (x: x);

  # Type: [a] -> [{ idx: int, val: a }]
  indexed = xs:
    imap1
      (i: x: {
        idx = i;
        val = x;
      })
      xs;

  # Type: ({ idx: int, val: a } -> bool) -> [{ idx: int, val: a }] -> int
  indexOf' = pred: xs:
    let xs' = filter pred xs;
    in if xs' == [ ] then throw "not found!" else let h = head xs'; in h.idx;
}
