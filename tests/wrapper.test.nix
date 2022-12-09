{ pkgs ? import <nixpkgs> { }, nixt }:
with pkgs.lib;

let
  inherit (builtins) map;
  inherit (pkgs) callPackage;
  dummy-plugin = callPackage ./dummy-plugin { };
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
nixt.mkSuites {
  "mappingPlugins" = {
    "empty" = (wrapper.mappingPlugins [ ]) == [ ];
    "start" = (wrapper.mappingPlugins [ (plugin // { optional = false; }) ])
      == [{
      plugin = dummy-plugin;
      optional = false;
    }];
    "opt" = (wrapper.mappingPlugins [ plugin ]) == [{
      plugin = dummy-plugin;
      optional = true;
    }];
  };
  "mappingPluginsWithOptimize" = {
    "empty" = (wrapper.mappingPluginsWithOptimize { excludePaths = [ ]; } [ ])
      == [ ];
    "start" = (wrapper.mappingPluginsWithOptimize { excludePaths = [ ]; }
      [ (plugin // { optional = false; }) ]) == [{
      plugin = dummy-plugin;
      optional = false;
    }];
    "opt" = (wrapper.mappingPluginsWithOptimize { excludePaths = [ ]; } [ plugin ]) == [{
      plugin = dummy-plugin;
      optional = true;
    }];
  };
}
