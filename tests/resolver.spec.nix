{ pkgs ? import <nixpkgs> { } }:
with pkgs.lib;

let
  inherit (builtins) map length head;
  inherit (pkgs) callPackage;
  inherit (pkgs.lib.lists) last;
  inherit (pkgs.lib.attrsets) attrValues filterAttrs;
  inherit (import ./../src/types.nix { inherit lib; })
    pluginUserConfigDefault;
  dummy-package = "package";
  dummy-plugin = { pname = "dumm-plugin"; };
  dummy2-plugin = { pname = "dummy2-plugin"; };
  dummy3-plugin = { pname = "dummy3-plugin"; };
  resolver = callPackage ./../src/resolver.nix { };

  normalized = {
    rokka = null;
    plugin = dummy-plugin;
    enable = true;
    optional = true;
    pname = "dummy";
    startup = null;
    config = "";
    comment = null;
    depends = [ ];
    dependsAfter = [ ];
    modules = [ ];
    events = [ ];
    fileTypes = [ ];
    commands = [ ];
    delay = false;
    optimize = true;
    extraPackages = [ ];
  };
  normalized2 = normalized // {
    plugin = dummy2-plugin;
    pname = "dummy2";
  };
  normalized3 = normalized // {
    plugin = dummy3-plugin;
    pname = "dummy3";
  };

  filterPlugin = filterAttrs (n: v: n == "plugin");

  resolveSpecs =
    let
      ps1 = [ (normalized // { optional = false; }) ];
      p2 = (normalized2 // {
        optimize = false;
        extraPackages = [ dummy-package ];
      });
      p1 = (normalized // {
        dependsAfter = [ p2 ];
        events = [ "InsertEnter" "BufWinEnter" ];
        modules = [ "dummymod" ];
        fileTypes = [ "nix" "lua" ];
        commands = [ "Open" "Close" ];
        delay = true;
      });
      ps2 = [ p1 ];
      ps3 = [
        (normalized // {
          depends = [ normalized2 ];
          enable = false;
        })
      ];
    in
    {
      test_resolvePlugins_start = {
        expr = resolver.resolvePlugins ps1;
        expected = {
          plugins = ps1;
          startPlugins = ps1;
          optPlugins = [ ];
          modulePlugins = { };
          eventPlugins = { };
          cmdPlugins = { };
          ftPlugins = { };
          delayPlugins = [ ];
          extraPackages = [ ];
        };
      };
      test_resolvePlugins_opt = {
        expr = resolver.resolvePlugins ps2;
        expected = {
          plugins = [ p1 p2 ];
          startPlugins = [ ];
          optPlugins = [ p1 p2 ];
          modulePlugins = { "dummymod" = [ "dummy" ]; };
          eventPlugins = {
            "InsertEnter" = [ "dummy" ];
            "BufWinEnter" = [ "dummy" ];
          };
          cmdPlugins = {
            "Open" = [ "dummy" ];
            "Close" = [ "dummy" ];
          };
          ftPlugins = {
            "nix" = [ "dummy" ];
            "lua" = [ "dummy" ];
          };
          delayPlugins = [ p1 ];
          extraPackages = [ dummy-package ];
        };
      };
      test_resolvePlugins_disabled = {
        expr = resolver.resolvePlugins ps3;
        expected = {
          plugins = [ ];
          startPlugins = [ ];
          optPlugins = [ ];
          modulePlugins = { };
          eventPlugins = { };
          cmdPlugins = { };
          ftPlugins = { };
          delayPlugins = [ ];
          extraPackages = [ ];
        };
      };
    };
in
{
  test_normalizePlugin_package = {
    expr = filterPlugin (resolver.normalizePlugin dummy-plugin);
    expected = filterPlugin normalized;
  };
  test_normalizePlugin_pluginUserConfigType_start = {
    expr = filterPlugin (resolver.normalizePlugin (pluginUserConfigDefault // {
      plugin = dummy-plugin;
      pname = "dummy";
    }));
    expected = filterPlugin normalized;
  };

  test_normalizePlugins_package = {
    expr = map filterPlugin (resolver.normalizePlugins
      [ (pluginUserConfigDefault // { plugin = dummy-plugin; }) ]);
    expected = map filterPlugin [ normalized ];
  };
  test_normalizePlugins_pluginUserConfigType = {
    expr = map filterPlugin (resolver.normalizePlugins [
      dummy-plugin
      (pluginUserConfigDefault // {
        plugin = dummy2-plugin;
        pname = "dummy2";
      })
    ]);
    expected = map filterPlugin [ normalized normalized2 ];
  };

  test_mergePlugin = {
    expr = resolver.mergePlugin normalized (normalized // {
      optional = false;
      startup = "startup";
      config = "config";
      comment = "comment";
      depends = [ normalized2 ];
      modules = [ "normalize2.nvim" ];
      fileTypes = [ "nix" ];
      events = [ "InsertEnter" ];
      commands = [ "Toggle" ];
      delay = true;
      optimize = false;
      extraPackages = [ dummy-package ];
    });
    expected = normalized // {
      optional = false;
      startup = "startup";
      config = "config";
      comment = "comment";
      depends = [ normalized2 ];
      modules = [ "normalize2.nvim" ];
      fileTypes = [ "nix" ];
      events = [ "InsertEnter" ];
      commands = [ "Toggle" ];
      delay = true;
      optimize = false;
      extraPackages = [ dummy-package ];
    };
  };

  test_flattenPlugins_flatten = {
    expr = (resolver.flattenPlugins
      [ (normalized // { depends = [ normalized2 ]; }) ]);
    expected = [ (normalized // { depends = [ normalized2 ]; }) normalized2 ];
  };
  test_flattenPlugins_dependsHasDisabled = {
    expr = resolver.flattenPlugins [
      (normalized // {
        depends = [
          (normalized2 // {
            enable = false;
            depends = [ normalized3 ];
          })
        ];
      })
    ];
    expected = [ normalized ];
  };
  test_flattenPlugins_dependsHasNestedDisabled = {
    expr = resolver.flattenPlugins [
      (normalized // {
        depends = [
          (normalized2 // {
            depends = [ (normalized3 // { enable = false; }) ];
          })
        ];
      })
    ];
    expected = [ (normalized // { depends = [ normalized2 ]; }) normalized2 ];
  };
  test_flattenPlugins_dependsAfterHasDisabled = {
    expr = resolver.flattenPlugins [
      (normalized // {
        dependsAfter = [ (normalized2 // { enable = false; }) ];
      })
    ];
    expected = [ normalized ];
  };
  test_flattenPlugins_dependsAfterHasNestedDisabled = {
    expr = resolver.flattenPlugins [
      (normalized // {
        dependsAfter = [
          (normalized2 // {
            enable = false;
            dependsAfter = [ normalized3 ];
          })
        ];
      })
    ];
    expected = [ normalized ];
  };

  test_aggregatePlugins = {
    expr = resolver.aggregatePlugins [
      normalized
      (normalized // { startup = "startup"; })
    ];
    expected = [ (normalized // { startup = "startup"; }) ];
  };
} // resolveSpecs
