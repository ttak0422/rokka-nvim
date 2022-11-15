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
  dummy3-plugin = callPackage ./dummy3-plugin { };
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
in
nixt.mkSuites {
  "normalizePlugin" = {
    "package" = (resolver.normalizePlugin dummy-plugin) == normalized;
    "pluginUserConfigType" = (resolver.normalizePlugin (pluginUserConfigDefault
      // {
      plugin = dummy-plugin;
      pname = "dummy";
    })) == normalized;
    "attr size" = (length (attrValues (resolver.normalizePlugin dummy-plugin)))
      == 17;
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
      modules = [ "normalize2.nvim" ];
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
      modules = [ "normalize2.nvim" ];
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
      })))) == 17;
  };

  "flattenPlugins" = {
    "flatten" = (resolver.flattenPlugins
      [ (normalized // { depends = [ normalized2 ]; }) ])
    == [ (normalized // { depends = [ normalized2 ]; }) normalized2 ];
    "flatten (disabled depends)" =
      let
        ps = (normalized // {
          depends = [
            (normalized2 // {
              enable = false;
              depends = [ normalized3 ];
            })
          ];
        });
      in
      (resolver.flattenPlugins [ ps ] == [ ps ]);
    "flatten (disabled depends) 2" =
      let
        ps = (normalized // {
          depends = [
            (normalized2 // {
              depends = [ (normalized3 // { enable = false; }) ];
            })
          ];
        });
      in
      (resolver.flattenPlugins [ ps ] == [
        ps
        (normalized2 // { depends = [ (normalized3 // { enable = false; }) ]; })
      ]);
    "flatten (disabled dependsAfter)" =
      let
        ps = (normalized // {
          dependsAfter = [ (normalized2 // { enable = false; }) ];
        });
      in
      (resolver.flattenPlugins [ ps ]) == [ ps ];
    "flatten (disabled dependsAfter) 2" =
      let
        ps = (normalized // {
          dependsAfter = [
            (normalized2 // {
              enable = false;
              dependsAfter = [ normalized3 ];
            })
          ];
        });
      in
      (resolver.flattenPlugins [ ps ] == [ ps ]);
  };

  "aggregatePlugins" = {
    "aggregate" = (resolver.aggregatePlugins [
      normalized
      (normalized // { startup = "startup"; })
    ]) == [ (normalized // { startup = "startup"; }) ];
    "attr size" =
      let
        ps = (resolver.aggregatePlugins [
          normalized
          (normalized // { startup = "startup"; })
        ]);
        h = head ps;
      in
      (length (attrValues h)) == 17;
  };

  "resolvePlugins" =
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

      resolveStart = resolver.resolvePlugins ps1;
      resolveOpt = resolver.resolvePlugins ps2;
      resolveDisabled = resolver.resolvePlugins ps3;
    in
    {
      "start" = resolveStart == {
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
      "opt plugins" = resolveOpt.plugins == [ p1 p2 ];
      "opt plugins size" = (length resolveOpt.plugins) == 2;
      "opt plugins head attr size" =
        let h = (head resolveOpt.plugins);
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
      "opt" = resolveOpt == {
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
      "disabled" = resolveDisabled == {
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
}
