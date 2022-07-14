{ pkgs, lib, stdenv, nix-filter, allPlugins }:
let
  inherit (builtins) map;
  inherit (pkgs.vimUtils) packDir;
  inherit (lib) filter;
  inherit (lib.strings) concatStringsSep optionalString;
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
      relocateFtdetectCmd = ''
        if [ -e ${plugin}/${rtp}/ftdetect ] && [ -n "$(ls ${plugin}/${rtp}/ftdetect)" ]; then
          mkdir -p $out/ftdetect/${name}
          ln -sf ${plugin}/${rtp}/ftdetect/* $out/ftdetect/${name}
        fi
      '';
      relocateFtpluginCmd = ''
        if [ -e ${plugin}/${rtp}/ftplugin ] && [ -n "$(ls ${plugin}/${rtp}/ftplugin)" ]; then
          mkdir -p $out/ftplugin/${name}
          ln -sf ${plugin}/${rtp}/ftplugin/* $out/ftplugin/${name}
        fi
      '';
    in (optionalString p.relocateFtdetect relocateFtdetectCmd)
    + (optionalString p.relocateFtplugin relocateFtpluginCmd);

  locatePluginsFt = map locatePluginFt;

  start = map (p: p.plugin) (filter (p: !p.optional) allPlugins');
  opt = map (p: p.plugin) (filter (p: p.optional) allPlugins');

in {
  pack = packDir { "${packpath}" = { inherit start opt; }; };
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
