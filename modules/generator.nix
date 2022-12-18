{ pkgs, lib, ... }:
let
  inherit (builtins) map length attrNames;
  inherit (pkgs) writeText;
  inherit (lib) concatStringsSep;
  inherit (lib.attrsets) mapAttrsToList;
  inherit (import ./util.nix lib) toLuaTableWith toLuaTable;

  concatC = concatStringsSep ",";

  # TODO: refactor
  # Type: pluginUserConfigType list -> str
  makeListConfig = ps: toLuaTableWith (p: "'${p.pname}'") ps;
  makeKvpConfig = ps:
    "{${
      concatC (mapAttrsToList
        (name: value: "['${name}']=${toLuaTable (map (x: "'${x}'") value)}") ps)
    }}";

  # Type: pluginUserConfigType -> str
  makeOptPluginConfig = p:
    let
      depends =
        if length (p.depends) > 0 then
          "opt_depends={${concatC (map (p': "'${p'.pname}'") p.depends)}},"
        else
          "";
      dependsAfter =
        if length (p.dependsAfter) > 0 then
          "opt_depends_after={${
          concatC (map (p': "'${p'.pname}'") p.dependsAfter)
        }},"
        else
          "";
    in
    "['${p.pname}']={${depends}${dependsAfter}}";

  # Type: pluginUserConfigType list -> str
  makeOptPluginsConfig = ps: "{${concatC (map makeOptPluginConfig ps)}}";
in
{
  # Type: pluginUserConfigType list -> package
  generateDelayLoadPluginsConfigFile = ps:
    writeText "delay.lua" ''
      return ${makeListConfig ps}
    '';

  # Type: pluginUserConfigType list -> package
  generatePluginDependsFile = ps:
    writeText "depends.lua" ''
      return ${makeOptPluginsConfig ps}
    '';

  # Type: Attrs[event,pname] -> package
  generateEventsFile = attr:
    writeText "events.lua" ''
      return ${toLuaTableWith (event: "'${event}'") (attrNames attr)}
    '';

  # Type: Attrs[event,pname] -> { event, package } list
  generateEventPluginsConfigFile = attr:
    mapAttrsToList
      (name: value: {
        event = name;
        package = writeText "${name}.lua" ''
          return ${toLuaTable (map (x: "'${x}'") value)}
        '';
      })
      attr;

  # Type: Attrs[ft,pname] -> package
  generateFtsFile = attr:
    writeText "fts.lua" ''
      return ${toLuaTableWith (event: "'${event}'") (attrNames attr)}
    '';

  # Type: Attrs[ft,pname] -> { event, package } list
  generateFtPluginsConfigFile = attr:
    mapAttrsToList
      (name: value: {
        ft = name;
        package = writeText "${name}.lua" ''
          return ${toLuaTable (map (x: "'${x}'") value)}
        '';
      })
      attr;

  # Type: Attrs[cmd,pname] -> package
  generateCmdsFile = attr:
    writeText "fts.lua" ''
      return ${toLuaTableWith (cmd: "'${cmd}'") (attrNames attr)}
    '';

  # Type: Attrs[cmd,pname] -> { event, package } list
  generateCmdPluginsConfigFile = attr:
    mapAttrsToList
      (name: value: {
        cmd = name;
        package = writeText "${name}.lua" ''
          return ${toLuaTable (map (x: "'${x}'") value)}
        '';
      })
      attr;
}
