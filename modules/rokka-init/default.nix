{ lib, plugins, optPlugins, allPlugins, allStartPlugins, allOptPlugins
, eventPlugins, commandPlugins, fileTypePlugins }:

let
  inherit (builtins) map toString length;
  inherit (lib) concatStringsSep filter;
  inherit (lib.lists) groupBy';
  inherit (lib.attrsets) mapAttrs mapAttrsToList;

  isNonNull = x: !(isNull x);
  concatC = concatStringsSep ",";
  concatN = concatStringsSep "\n";

  simpleSetToTable = s:
    "{ ${concatC (mapAttrsToList (k: v: k + "='" + (toString v) + "'") s)}}";

  simpleListToTable = f: xs: "{${concatC (map f xs)}}";

  mkOptPluginConfig = p: ''
    ["${p.plugin.pname}"] = {
      loaded = false,
      config = ${
        if isNonNull p.config then "function() ${p.config} end" else "nil"
      },
      opt_depends = ${simpleListToTable (p': "'${p'.plugin.pname}'") p.depends},
    }
  '';

  makeStartupConfig = p: ''
    -- ${p.plugin.pname}
    ${p.startup}
  '';

  makeRokkaInit = { config }:
    let
      startupConfigs = let plugin' = filter (p: p.startup != null) allPlugins;
      in concatN (map makeStartupConfig plugin');
      evPlugins = let
        ps = groupBy' (acc: x: acc ++ [ x.name ]) [ ] (x: x.event) eventPlugins;
      in mapAttrs (name: value: simpleListToTable (p: "'${p}'") value) ps;
      cmdPlugins = let
        ps = groupBy' (acc: x: acc ++ [ x.name ]) [ ] (x: x.command)
          commandPlugins;
      in mapAttrs (name: value: simpleListToTable (p: "'${p}'") value) ps;
      ftPlugins = let
        ps = groupBy' (acc: x: acc ++ [ x.plugin.pname ]) [ ] (x: x.fileType)
          fileTypePlugins;
      in mapAttrs (name: value: simpleListToTable (p: "'${p}'") value) ps;
      delayPlugins = filter (p: p.delay) optPlugins;
    in ''
      -- info --
      -- plugin
      -- start + opt : ${toString (length allPlugins)}
      -- start       : ${toString (length allStartPlugins)}
      -- opt         : ${toString (length allOptPlugins)}

      vim.cmd [[packadd rokka.nvim]]

      local rokka = require 'rokka'

      config = {
        opt_plugins = {
          ${concatC (map mkOptPluginConfig allOptPlugins)}
        },

        log_plugin = "${config.log_plugin}",
        log_level = "${config.log_level}",

        loader_event_plugins = {
          ${
            concatC
            (mapAttrsToList (name: value: "['${name}']=${value}") evPlugins)
          }
        },
        loader_cmd_plugins = {
          ${
            concatC
            (mapAttrsToList (name: value: "['${name}']=${value}") cmdPlugins)
          }
        },
        loader_ft_plugins = {
          ${
            concatC
            (mapAttrsToList (name: value: "['${name}']=${value}") ftPlugins)
          }
        },
        loader_delay_plugins = ${
          simpleListToTable (p: "'${p.plugin.pname}'") delayPlugins
        },
        loader_delay_time = ${toString config.loader_delay_time},
      }

      rokka.init(config)

      ---------------------
      -- Startup configs --
      ---------------------
      ${startupConfigs}
    '';

in { inherit makeRokkaInit; }
