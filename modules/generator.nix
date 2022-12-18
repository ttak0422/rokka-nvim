{ pkgs, lib, ... }:
let
  inherit (pkgs) writeText;
  inherit (import ./util.nix lib) toLuaTableWith toLuaTable;

  # TODO: refactor
  # Type: pluginUserConfigType list -> str
  makeListConfig = ps: toLuaTableWith (p: "'${p.pname}'") ps;
in
{
  # Type: pluginUserConfigType list -> package
  generateDelayLoadPluginsConfigFile = ps:
    writeText "delay.lua" ''
      return ${makeListConfig ps}
    '';
}
