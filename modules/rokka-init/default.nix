{ config, lib }:
let
  inherit (builtins) map toString;
  inherit (lib) concatStringsSep;
  inherit (lib.lists) flatten;
  inherit (lib.attrsets) mapAttrsToList;

  concatC = concatStringsSep ",";
  concatN = concatStringsSep "\n";
  setToTable = s:
    "{ ${concatC (mapAttrsToList (k: v: k + "='" + (toString v) + "'") s)}}";

  makeInitConfig = p:
    let configs = flatten [ p.init (if !p.opt then p.onLoad else [ ]) ];
    in concatN configs;

  # WIP
  makeOnLoad = p: "";

  makeRokkaInit = { config, plugins }:
    let
      initConfigs = concatN (map makeInitConfig plugins);
      onLoadConfigs = concatN (map makeOnLoad plugins);
    in ''
      vim.cmd [[packadd rokka.nvim]]

      local rokka = require 'rokka'

      rokka.init(${setToTable config})

      -- Init configs --
      ${initConfigs}

      -- OnLoad configs --
      ${onLoadConfigs}
    '';

in { inherit makeRokkaInit; }
