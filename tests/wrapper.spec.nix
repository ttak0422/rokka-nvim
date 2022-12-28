{ pkgs ? import <nixpkgs> { } }:
with pkgs.lib;

let
  inherit (builtins) map;
  inherit (pkgs) callPackage;
  inherit (pkgs.stdenv) mkDerivation;
  dummy-plugin = { pname = "dummy"; };
  wrapper = callPackage ./../modules/wrapper.nix {
    # dummy
    nix-filter = { root, ... }: root;
  };

  plugin = {
    rokka = null;
    plugin = dummy-plugin;
    enable = true;
    optional = true;
    pname = "dummy";
    startup = "-- startup";
    config = "-- config";
    comment = "comment";
    depends = [ ];
    dependsAfter = [ ];
    events = [ ];
    fileTypes = [ ];
    commands = [ ];
    delay = true;
    optimize = true;
    extraPackages = [ ];
  };
in
{
  test_mappingPlugins_empty = {
    expr = wrapper.mappingPlugins [ ];
    expected = [ ];
  };
  test_mappingPlugins_start = {
    expr = wrapper.mappingPlugins [ (plugin // { optional = false; }) ];
    expected = [{
      plugin = dummy-plugin;
      optional = false;
    }];
  };
  test_mappingPlugins_opt = {
    expr = wrapper.mappingPlugins [ plugin ];
    expected = [{
      plugin = dummy-plugin;
      optional = true;
    }];
  };
}
