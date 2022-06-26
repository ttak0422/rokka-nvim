{ pkgs, lib, stdenv, nix-filter, allPlugins }:
let
  inherit (builtins) map;
  inherit (pkgs.vimUtils) packDir;
  inherit (lib) filter;
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

  allPlugins' = map
    (p: if p.optimize then p // { plugin = optimizePackage p.plugin; } else p)
    allPlugins;

  locatePluginFt = p:
    let
      name = p.pname;
      rtp = if isNull p.rtp then "" else p.rtp;
      plugin = p.plugin;
    in ''
      if [ -e ${plugin}/${rtp}/ftdetect ] && [ -n "$(ls ${plugin}/${rtp}/ftdetect)" ]; then
        mkdir -p $out/ftdetect/${name}
        ln -sf ${plugin}/${rtp}/ftdetect/* $out/ftdetect/${name}
      fi

      if [ -e ${plugin}/${rtp}/ftplugin ] && [ -n "$(ls ${plugin}/${rtp}/ftplugin)" ]; then
        mkdir -p $out/ftplugin/${name}
        ln -sf ${plugin}/${rtp}/ftplugin/* $out/ftplugin/${name}
      fi
    '';

  locatePluginsFt = map locatePluginFt;

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

  start = map (p: p.plugin) (filter (p: !p.optional) allPlugins');
  opt = map (p: p.plugin) (filter (p: p.optional) allPlugins');

in {
  pack = packDir { packpath = { inherit start opt; }; };
  ft = mkDerivation {
    name = "rokka-ft";
    src = ./.;
    preferLocalBuild = true;
    installPhase = ''
      mkdir -p $out/ftdetect
      mkdir -p $out/ftplugin
    '' + (concatStringsSep "\n"
      (locatePluginsFt (filter (p: p.optimize) allPlugins)));
  };
}
