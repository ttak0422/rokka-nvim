{ config, lib }:
let
  inherit (builtins) map toString;
  inherit (lib) concatStringsSep filter;
  inherit (lib.lists) flatten;
  inherit (lib.attrsets) mapAttrsToList;

  isNonNull = x: !(isNull x);
  concatC = concatStringsSep ",";
  concatN = concatStringsSep "\n";
  simpleSetToTable = s:
    "{ ${concatC (mapAttrsToList (k: v: k + "='" + (toString v) + "'") s)}}";

  /* Type: mkLuaListCode :: (a -> str) -> [a] -> str

     Example
       mkLuaListCode (x: "'${x.name}'") [ { name = "foo"; } { name = "bar"; } ]
       => "{'foo','bar'}"
  */
  mkLuaListCode = f: xs: "{${concatC (map f xs)}}";

  makeStartupConfig = p:
    if isNonNull p.startup then ''
      -- ${p.plugin.pname}
      ${p.startup}
    '' else
      null;

  # WIP
  makeConfig = p:
    if isNonNull p.config then ''
      -- ${p.plugin.pname}
      ${p.config}
    '' else
      null;

  makeRokkaInit = { config, plugins }:
    let
      startupConfigs =
        concatN (filter isNonNull (map makeStartupConfig plugins));
      configs = concatN (filter isNonNull (map makeConfig plugins));
      delayPlugins = filter (p: p.delay) plugins;
    in ''
      vim.cmd [[packadd rokka.nvim]]

      local rokka = require 'rokka'

      config = {
        log_plugin = "${config.log_plugin}",
        log_level = "${config.log_level}",

        loader_delay_plugins = ${
          mkLuaListCode (p: "'${p.plugin.pname}'") delayPlugins
        },
        loader_delay_time = ${toString config.loader_delay_time},
      }

      rokka.init(config)

      ---------------------
      -- Startup configs --
      ---------------------
      ${startupConfigs}

      -------------
      -- Configs --
      -------------
      ${configs}
    '';

in { inherit makeRokkaInit; }
