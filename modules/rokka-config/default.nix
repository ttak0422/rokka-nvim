{ pkgs, lib, stdenv, pluginsConfigs, delayPlugins }:

/*
 * $out/plugin/...
 * $out/delayplugins
 */

let
  inherit (stdenv) mkDerivation;
  inherit (pkgs) writeText;
  inherit (lib.strings) concatStringsSep;
  inherit (import ./../util.nix lib) toLuaTableWith;
in
let
  locatePluginsConfigFile = p:
    "cp ${writeText p.pname p.config} $out/plugin/${p.pname}";
  locateDelayPluginsConfigFile = ps:
    let
      file = writeText "delayPlugins" ''
        return ${toLuaTableWith (p: "'${p.pname}'") ps}
      '';
    in
    "cp ${file} $out/delayPlugins";
in
mkDerivation {
  pname = "rokka-config";
  version = "0.0.1";
  src = ./.;
  preferLocalBuild = true;
  installPhase = concatStringsSep "\n" ([ "mkdir $out" "mkdir $out/plugin" ]
    ++ (map locatePluginsConfigFile pluginsConfigs)
    ++ [ (locateDelayPluginsConfigFile delayPlugins) ]);
}
