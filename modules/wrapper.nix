{ pkgs, lib, ... }:

let
  inherit (builtins) map;
  inherit (pkgs) writeText;
  inherit (lib) concatStringsSep filter;
  inherit (lib.attrsets) mapAttrsToList;
  inherit (import ./util.nix lib) toLuaTableWith toLuaTable;
  concatC = concatStringsSep ",";
  concatN = concatStringsSep "\n";

  # Type:
  #   pluginUserConfigType (rokka.nvim) -> pluginWithConfigType (home-manager)
  # Doc:
  #   mapping plugin's config.
  # Note:
  #   some options are missing and have to configure elsewhere.
  mappingPlugin = p: {
    plugin = p.plugin;
    optional = p.optional;
  };

  # Type: pluginUserConfigType list -> str
  makeStartupConfig = ps:
    let targets = filter (p: p.startup != null) ps;
    in
    concatN (map
      (p: ''
        -- ${p.pname}
        ${p.startup}
      '')
      targets);

  # Type: pluginUserConfigType list -> str
  makeStartPluginsConfig = ps:
    let targets = filter (p: p.config != null) ps;
    in
    concatN (map
      (p: ''
        -- ${p.pname}
        ${p.config}
      '')
      targets);

  # Type: pluginUserConfigType -> str
  makeOptPluginConfig = p:
    let
      depends = "{${concatC (map (p': "'${p'.pname}'") p.depends)}}";
      dependsAfter = "{${concatC (map (p': "'${p'.pname}'") p.dependsAfter)}}";
    in
    ''
      ['${p.pname}'] = {
        loaded = false,
        config = ${
          if p.config != null then
            "function() dofile('${writeText p.pname p.config}') end"
          else
            "nil"
        },
        opt_depends = ${depends},
        opt_depends_after = ${dependsAfter},
      }
    '';

  # Type: pluginUserConfigType list -> str
  makeOptPluginsConfig = ps: "{${concatC (map makeOptPluginConfig ps)}}";

  # Type: pluginUserConfigType list -> str
  makeListConfig = ps: toLuaTableWith (p: "'${p.pname}'") ps;
  makeKvpConfig = ps:
    "{${
      concatC (mapAttrsToList
        (name: value: "['${name}']=${toLuaTable (map (x: "'${x}'") value)}") ps)
    }}";

  # Type: obj -> package
  makePluginsConfigFile = cfg:
    let ftPlugins = { };
    in
    writeText "rokka-init.lua" ''
      local rokka = require 'rokka'
      rokka.init({
        log_plugin = '${cfg.log_plugin}',
        log_level = '${cfg.log_level}',
        loader_delay_time = ${toString cfg.loader_delay_time},
        opt_plugins = ${makeOptPluginsConfig cfg.optPlugins},
        loader_module_plugins = ${makeKvpConfig cfg.modulePlugins},
        loader_event_plugins = ${makeKvpConfig cfg.eventPlugins},
        loader_cmd_plugins = ${makeKvpConfig cfg.cmdPlugins},
        loader_ft_plugins = ${makeKvpConfig cfg.ftPlugins},
        loader_delay_plugins = ${makeListConfig cfg.delayPlugins},
      })

      -------------
      -- startup --
      -------------
      ${makeStartupConfig cfg.plugins}

      ------------------
      -- start/config --
      ------------------
      ${makeStartPluginsConfig cfg.startPlugins}
    '';

in
rec {
  # Type: pluginUserConfigType list (rokka.nvim) -> pluginWithConfigType list (home-manager)
  mappingPlugins = ps: map mappingPlugin ps;

  # Type: obj -> package
  makePluginsConfig = cfg: ''
    lua dofile('${makePluginsConfigFile cfg}')
  '';

}
