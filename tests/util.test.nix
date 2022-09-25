{ pkgs ? import <nixpkgs> { }, nixt }:

with pkgs.lib;

let util = import ./../modules/util.nix pkgs.lib;
in nixt.mkSuites {
  "list util" = let
    xs = [
      {
        name = "foo";
        age = 10;
      }
      {
        name = "bar";
        age = 20;
      }
      {
        name = "foo";
        age = 20;
      }
    ];
    ys = [
      {
        name = "foo";
        age = 20;
      }
      {
        name = "bar";
        age = 30;
      }
    ];
  in {
    "uniqueWith name" = (util.uniqueWith (x: x.name) xs) == [
      {
        name = "foo";
        age = 10;
      }
      {
        name = "bar";
        age = 20;
      }
    ];

    "elemWith name" = (util.elemWith (y: y.name) {
      name = "foo";
      age = 10;
    } ys) == true;
    "elemWith age" = (util.elemWith (y: y.age) {
      name = "foo";
      age = 10;
    } ys) == false;

    "expandWith" = let xs = [ "foo" "bar" "baz" ];
    in (util.expandWith (x: x.items) (src: x: src // { item = x; }) {
      items = xs;
    }) == [
      {
        item = "foo";
        items = xs;
      }
      {
        item = "bar";
        items = xs;
      }
      {
        item = "baz";
        items = xs;
      }
    ];
  };
}
