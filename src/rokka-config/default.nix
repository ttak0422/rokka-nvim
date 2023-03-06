{ pkgs
, lib
, stdenv
, pluginsConfigs
, delayPlugins
, modulePlugins
, eventPlugins
, cmdPlugins
, ftPlugins
}:

# $out/plugin/...
# $out/plugin/depends/...
# $out/plugin/dependsAfter/...
# $out/mod/...
# $out/ev/...
# $out/cmd/...
# $out/ft/...
# $out/delayplugins

let
  inherit (stdenv) mkDerivation;
  inherit (pkgs) writeText;
  inherit (lib.strings) concatStringsSep;
  inherit (lib.attrsets) mapAttrsToList;
  inherit (import ./../util.nix lib) toLuaTableWith;
in
let
  locatePluginsConfigFile = p:
    "cp ${writeText p.pname p.config} $out/plugin/${p.pname}";
  locatePluginDepndsFile = plugin: depends:
    let
      file = writeText "depends" ''
        return ${toLuaTableWith (p: "'${p.pname}'") depends}
      '';
    in
    "cp ${file} $out/plugin/depends/${plugin}";
  locatePluginDepndsFiles = map (p: locatePluginDepndsFile p.pname p.depends);
  locatePluginDepndsAfterFile = plugin: dependsAfter:
    let
      file = writeText "dependsAfter" ''
        return ${toLuaTableWith (p: "'${p.pname}'") dependsAfter}
      '';
    in
    "cp ${file} $out/plugin/dependsAfter/${plugin}";
  locatePluginDepndsAfterFiles =
    map (p: locatePluginDepndsAfterFile p.pname p.dependsAfter);
  # Type: str -> [str] -> str
  locateModPluginConfigFile = mod: ps:
    let
      file = writeText "mod" ''
        return ${toLuaTableWith (p: "'${p}'") ps}
      '';
    in
    "cp ${file} $out/mod/${mod}";
  # Type: [{ name: str, value: [str] }] -> [str]
  locateModPluginConfigFiles = mapAttrsToList locateModPluginConfigFile;
  # Type: str -> [str] -> str
  locateEvPluginConfigFile = ev: ps:
    let
      file = writeText "ev" ''
        return ${toLuaTableWith (p: "'${p}'") ps}
      '';
    in
    "cp ${file} $out/ev/${ev}";
  # Type: [{ name: str, value: [str] }] -> [str]
  locateEvPluginConfigFiles = mapAttrsToList locateEvPluginConfigFile;
  # Type: str -> [str] -> str
  locateCmdPluginConfigFile = cmd: ps:
    let
      file = writeText "cmd" ''
        return ${toLuaTableWith (p: "'${p}'") ps}
      '';
    in
    "cp ${file} $out/cmd/${cmd}";
  # Type: [{ name: str, value: [str] }] -> [str]
  locateCmdPluginConfigFiles = mapAttrsToList locateCmdPluginConfigFile;
  # Type: str -> [str] -> str
  locateFtPluginConfigFile = ft: ps:
    let
      file = writeText "ft" ''
        return ${toLuaTableWith (p: "'${p}'") ps}
      '';
    in
    "cp ${file} $out/ft/${ft}";
  # Type: [{ name: str, value: [str] }] -> [str]
  locateFtPluginConfigFiles = mapAttrsToList locateFtPluginConfigFile;
  # Type: [str] -> str
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
  installPhase = concatStringsSep "\n" ([
    "mkdir $out"
    "mkdir $out/plugin"
    "mkdir $out/plugin/depends"
    "mkdir $out/plugin/dependsAfter"
    "mkdir $out/mod"
    "mkdir $out/ev"
    "mkdir $out/cmd"
    "mkdir $out/ft"
  ] ++ (map locatePluginsConfigFile pluginsConfigs)
  ++ (locatePluginDepndsFiles pluginsConfigs)
  ++ (locatePluginDepndsAfterFiles pluginsConfigs)
  ++ (locateModPluginConfigFiles modulePlugins)
  ++ (locateEvPluginConfigFiles eventPlugins)
  ++ (locateCmdPluginConfigFiles cmdPlugins)
  ++ (locateFtPluginConfigFiles ftPlugins)
  ++ [ (locateDelayPluginsConfigFile delayPlugins) ]);
}
