{ pkgs ? import <nixpkgs> { } }:

let
  util = import ./../src/util.nix pkgs.lib;
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
in
{
  test_uniqueWith_name = {
    expr = util.uniqueWith (x: x.name) xs;
    expected = [
      {
        name = "foo";
        age = 10;
      }
      {
        name = "bar";
        age = 20;
      }
    ];
  };
  test_elemWith_name = {
    expr = util.elemWith (y: y.name)
      {
        name = "foo";
        age = 10;
      }
      ys;
    expected = true;
  };
  test_elemWith_age = {
    expr = util.elemWith (y: y.age)
      {
        name = "foo";
        age = 10;
      }
      ys;
    expected = false;
  };
  test_expandWith =
    let xs = [ "foo" "bar" "baz" ];
    in {
      expr = util.expandWith (x: x.items) (src: x: src // { item = x; }) {
        items = xs;
      };
      expected = [
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
  test_mergeElement_useDefault = {
    expr = util.mergeElement 1 1 1 "use default value";
    expected = 1;
  };
  test_mergeElement_useOther = {
    expr = util.mergeElement true true false "use other value";
    expected = true;
  };
}
