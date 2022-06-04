{ config, lib, rokka-util }:
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
    in ''
      vim.cmd [[packadd rokka.nvim]]

      local rokka = require 'rokka'

      rokka.init(${simpleSetToTable config})

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
