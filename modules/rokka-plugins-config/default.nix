{ pkgs, lib, stdenv, pluginsConfigs }:
let
  inherit (stdenv) mkDerivation;
  inherit (pkgs) writeText;
  inherit (lib.strings) concatStringsSep;
in
let
  locateConfigFile = p: "cp ${writeText p.pname p.config} $out/${p.pname}";
in
mkDerivation {
  pname = "rokka-plugins-config";
  version = "0.0.1";
  src = ./.;
  preferLocalBuild = true;
  installPhase =
    concatStringsSep "\n"
      ([ "mkdir $out" ] ++ (map locateConfigFile pluginsConfigs));
}
