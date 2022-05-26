{ lib, stdenv, plugins }:
let
  inherit (lib.strings) concatStringsSep;
  inherit (stdenv) mkDerivation;

  packpath = "rokka";

  # start/opt directories must be created before this.
  locatePlugin = p:
    let
      dir = if p.opt then "opt" else "start";
      name = if p.as != "" then p.as else p.plugin.pname;
    in "ln -sf ${p.plugin}/${p.rtp} $out/pack/${packpath}/${dir}/${name}";

  locatePlugins = builtins.map locatePlugin;
in mkDerivation {
  name = "rokka-pack";
  src = ./.;
  preferLocalBuild = true;
  installPhase = concatStringsSep "\n" ([
    "mkdir -p $out/pack/${packpath}/start"
    "mkdir -p $out/pack/${packpath}/opt"
  ] ++ (locatePlugins plugins));
}
