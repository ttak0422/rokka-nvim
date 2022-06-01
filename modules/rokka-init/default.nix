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

  makeStartupConfig = p:
    if isNonNull p.startup then ''
      -- ${p.pname}
      ${p.startup}
    '' else
      null;

  makeConfig = p:
    let
      simpleConfig = p: ''
        -- ${p.pname}
        ${p.config}
      '';
      smartConfig = p: ''
        -- WIP
      '';
    in if isNull p.config then
      null
    else if !p.opt then
      simpleConfig p
    else
      smartConfig p;

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
      ${initConfigs}

      -------------
      -- Configs --
      -------------
      ${configs}
    '';

in { inherit makeRokkaInit; }
