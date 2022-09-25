{ pkgs ? import <nixpkgs> { }, nixt }:
with pkgs.lib;

let
  inherit (builtins) map length head;
  inherit (pkgs) callPackage;
  inherit (pkgs.lib.lists) last;
  inherit (pkgs.lib.attrsets) attrValues;
  inherit (import ./../modules/types.nix { inherit lib; })
    pluginUserConfigDefault;
  dummy-package = callPackage ./dummy-package { };
  dummy-plugin = callPackage ./dummy-plugin { };
  dummy2-plugin = callPackage ./dummy2-plugin { };
  resolver = callPackage ./../modules/resolver.nix { };

  normalized = {
    rokka = null;
    plugin = dummy-plugin;
    enable = true;
    optional = true;
    pname = "dummy";
    startup = null;
    config = null;
    comment = null;
    depends = [ ];
    dependsAfter = [ ];
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
in nixt.mkSuites {
  "normalizePlugin" = {
    "package" = (resolver.normalizePlugin dummy-plugin) == normalized;
    "pluginUserConfigType" = (resolver.normalizePlugin (pluginUserConfigDefault
      // {
        plugin = dummy-plugin;
        pname = "dummy";
      })) == normalized;
    "attr size" = (length (attrValues (resolver.normalizePlugin dummy-plugin)))
      == 16;
  };

  "normalizePlugins" = {
    "package" = (resolver.normalizePlugins [ dummy-plugin ]) == [ normalized ];
    "pluginUserConfigType" = (resolver.normalizePlugins
      [ (pluginUserConfigDefault // { plugin = dummy-plugin; }) ])
      == [ normalized ];
    "mix" = (resolver.normalizePlugins [
      dummy-plugin
      (pluginUserConfigDefault // {
        plugin = dummy2-plugin;
        pname = "dummy2";
      })
    ]) == [ normalized normalized2 ];
  };

  "mergePlugin" = {
    "merge" = (resolver.mergePlugin normalized (normalized // {
      optional = false;
      startup = "startup";
      config = "config";
      comment = "comment";
      depends = [ normalized2 ];
      fileTypes = [ "nix" ];
      events = [ "InsertEnter" ];
      commands = [ "Toggle" ];
      delay = true;
      optimize = false;
      extraPackages = [ dummy-package ];
    })) == (normalized // {
      optional = false;
      startup = "startup";
      config = "config";
      comment = "comment";
      depends = [ normalized2 ];
      fileTypes = [ "nix" ];
      events = [ "InsertEnter" ];
      commands = [ "Toggle" ];
      delay = true;
      optimize = false;
      extraPackages = [ dummy-package ];
    });
    "attr size" = (length (attrValues (resolver.mergePlugin normalized
      (normalized // {
        optional = false;
        startup = "startup";
        config = "config";
        comment = "comment";
        depends = [ normalized2 ];
        fileTypes = [ "nix" ];
        events = [ "InsertEnter" ];
        commands = [ "Toggle" ];
        delay = true;
        optimize = false;
        extraPackages = [ dummy-package ];
      })))) == 16;
  };

  "flattenPlugins" = {
    "flatten" = (resolver.flattenPlugins
      [ (normalized // { depends = [ normalized2 ]; }) ])
      == [ (normalized // { depends = [ normalized2 ]; }) normalized2 ];
    "attr size" = let
      ps = (resolver.flattenPlugins
        [ (normalized // { depends = [ normalized2 ]; }) ]);
      h = head ps;
      l = last ps;
    in (length (attrValues h)) == 16 && (length (attrValues l)) == 16;
  };

  "aggregatePlugins" = {
    "aggregate" = (resolver.aggregatePlugins [
      normalized
      (normalized // { startup = "startup"; })
    ]) == [ (normalized // { startup = "startup"; }) ];
    "attr size" = let
      ps = (resolver.aggregatePlugins [
        normalized
        (normalized // { startup = "startup"; })
      ]);
      h = head ps;
    in (length (attrValues h)) == 16;
  };

  "resolvePlugins" = let
    ps1 = [ (normalized // { optional = false; }) ];
    p2 = (normalized2 // {
      optimize = false;
      extraPackages = [ dummy-package ];
    });
    p1 = (normalized // {
      dependsAfter = [ p2 ];
      events = [ "InsertEnter" "BufWinEnter" ];
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

    resolveStart = resolver.resolvePlugins ps1;
    resolveOpt = resolver.resolvePlugins ps2;
    resolveDisabled = resolver.resolvePlugins ps3;
  in {
    "start" = resolveStart == {
      plugins = ps1;
      startPlugins = ps1;
      optPlugins = [ ];
      eventPlugins = { };
      cmdPlugins = { };
      ftPlugins = { };
      delayPlugins = [ ];
      extraPackages = [ ];
    };
    "opt plugins" = resolveOpt.plugins == [ p1 p2 ];
    "opt plugins size" = (length resolveOpt.plugins) == 2;
    "opt plugins head attr size" = let h = (head resolveOpt.plugins);
    in (length (attrValues h)) == (length (attrValues p1));

    "opt plugins head" = let h = (head resolveOpt.plugins); in h == p1;
    "opt plugins last" = (last resolveOpt.plugins) == p2;
    "opt startPlugins" = resolveOpt.startPlugins == [ ];
    "opt optPlugins" = resolveOpt.optPlugins == [ p1 p2 ];
    "opt event InsertEnter size" =
      (length resolveOpt.eventPlugins."InsertEnter") == 1;
    "opt event" = resolveOpt.eventPlugins == {
      "InsertEnter" = [ "dummy" ];
      "BufWinEnter" = [ "dummy" ];
    };
    "opt" = let x = 1;
    in resolveOpt == {
      plugins = [ p1 p2 ];
      startPlugins = [ ];
      optPlugins = [ p1 p2 ];
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
    "disabled" = resolveDisabled == {
      plugins = [ ];
      startPlugins = [ ];
      optPlugins = [ ];
      eventPlugins = { };
      cmdPlugins = { };
      ftPlugins = { };
      delayPlugins = [ ];
      extraPackages = [ ];
    };
  };
}
