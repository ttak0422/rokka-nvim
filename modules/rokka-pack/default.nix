{ lib, stdenv, nix-filter, allPlugins }:
let
  inherit (builtins) map;
  inherit (lib.strings) concatStringsSep;
  inherit (stdenv) mkDerivation;

  packpath = "rokka";

  optimizePackage = package:
    package.overrideAttrs (old: {
      src = nix-filter {
        root = package.src;
        exclude = [
          "LICENSE"
          "README"
          "README.md"
          "t"
          "test"
          "tests"
          "Makefile"
          ".gitignore"
          ".git"
          ".github"
          "ftplugin"
          "ftdetect"
        ];
      };
    });

  # start/opt directories must be created before this.
  locateOptimizedPlugin = p:
    let
      dir = if p.optional then "opt" else "start";
      name = p.pname;
      rtp = if isNull p.rtp then "" else p.rtp;
      origin = p.plugin;
      optimized = optimizePackage origin;
    in ''
      if [ -e ${origin}/${rtp}/ftdetect ] && [ -n "$(ls ${origin}/${rtp}/ftdetect)" ]; then
        mkdir -p $out/ftdetect/${name}
        ln -sf ${origin}/${rtp}/ftdetect/* $out/ftdetect/${name}
      fi

      if [ -e ${origin}/${rtp}/ftplugin ] && [ -n "$(ls ${origin}/${rtp}/ftplugin)" ]; then
        mkdir -p $out/ftplugin/${name}
        ln -sf ${origin}/${rtp}/ftplugin/* $out/ftplugin/${name}
      fi

      ln -sf ${optimized}/${rtp} $out/pack/${packpath}/${dir}/${name}
    '';

  # start/opt directories must be created before this.
  locateNormalPlugin = p:
    let
      dir = if p.optional then "opt" else "start";
      name = p.pname;
      rtp = if isNull p.rtp then "" else p.rtp;
      plugin = p.plugin;
    in "ln -sf ${plugin}/${rtp} $out/pack/${packpath}/${dir}/${name}";

  locatePlugins = map
    (p: if p.optimize then locateOptimizedPlugin p else locateNormalPlugin p);

in mkDerivation {
  name = "rokka-pack";
  src = ./.;
  preferLocalBuild = true;
  installPhase = concatStringsSep "\n" ([
    "mkdir -p $out/pack/${packpath}/start"
    "mkdir -p $out/pack/${packpath}/opt"
  ] ++ (locatePlugins allPlugins));
}
