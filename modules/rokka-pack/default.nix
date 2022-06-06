{ lib, stdenv, allPlugins }:
let
  inherit (builtins) map;
  inherit (lib.strings) concatStringsSep;
  inherit (stdenv) mkDerivation;

  packpath = "rokka";

  # start/opt directories must be created before this.
  locatePlugin = p:
    let
      dir = if p.optional then "opt" else "start";
      name = p.name;
      rtp = if isNull p.rtp then "" else p.rtp;
      plugin = p.plugin;
    in "ln -sf ${plugin}/${rtp} $out/pack/${packpath}/${dir}/${name}";

  locatePlugins = map locatePlugin;

in mkDerivation {
  name = "rokka-pack";
  src = ./.;
  preferLocalBuild = true;
  installPhase = concatStringsSep "\n" ([
    "mkdir -p $out/pack/${packpath}/start"
    "mkdir -p $out/pack/${packpath}/opt"
  ] ++ (locatePlugins allPlugins));
}
