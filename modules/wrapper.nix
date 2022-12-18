{ pkgs, lib, nix-filter, ... }:

let
  inherit (builtins) map length;
  inherit (pkgs) callPackage writeText;
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

  # Type:
  #   opt -> pluginUserConfigType (rokka.nvim) -> pluginWithConfigType (home-manager)
  # Doc:
  #   mapping plugin's config with optimize.
  # Note:
  #   some options are missing and have to configure elsewhere.
  mappingPluginWithOptimize = opt: p: {
    plugin =
      if p.optimize then
        p.plugin.overrideAttrs
          (old: {
            src = nix-filter {
              root = p.plugin.src;
              exclude = opt.excludePaths;
            };
          })
      else
        p.plugin;
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

  # Type: pluginUserConfigType list -> package
  makeOptPluginsConfigFiles = ps:
    callPackage ./rokka-plugins-config {
      # configFiles = map (p: writeText p.pname p.config) ps;
      pluginsConfigs = ps;
    };

  # Type: pluginUserConfigType list -> str
  makeListConfig = ps: toLuaTableWith (p: "'${p.pname}'") ps;
  makeKvpConfig = ps:
    "{${
      concatC (mapAttrsToList
        (name: value: "['${name}']=${toLuaTable (map (x: "'${x}'") value)}") ps)
    }}";

  # Type: obj -> package
  makeExtraConfigLuaFile = cfgText: writeText "rokka-extraconfig.lua" cfgText;

  # Type: obj -> str
  makePluginsConfigLua = cfg:
    let
      initParams = [
        "log_plugin='${cfg.log_plugin}'"
        "log_level='${cfg.log_level}'"
        "loader_delay_time=${toString cfg.loader_delay_time}"
        "opt_plugins=${makeOptPluginsConfig cfg.optPlugins}"
        "plugins_config_root='${makeOptPluginsConfigFiles cfg.optPlugins}/'"
        "loader_module_plugins=${makeKvpConfig cfg.modulePlugins}"
        "loader_event_plugins=${makeKvpConfig cfg.eventPlugins}"
        "loader_cmd_plugins=${makeKvpConfig cfg.cmdPlugins}"
        "loader_ft_plugins=${makeKvpConfig cfg.ftPlugins}"
      ];
      initParams' = concatC initParams;
    in
    ''
      local rokka = require('rokka')
      local logger = require('rokka.log')
      rokka.init({${initParams'}})
      -------------
      -- startup --
      -------------
      ${makeStartupConfig cfg.plugins}
      ------------------
      -- start/config --
      ------------------
      ${makeStartPluginsConfig cfg.startPlugins}
    '';

  # Type: obj -> package
  makePluginsConfigLuaFile = cfg:
    writeText "rokka-init.lua" (makePluginsConfigLua cfg);

in
rec {
  inherit makePluginsConfigLua makePluginsConfigLuaFile;

  # Type: pluginUserConfigType list (rokka.nvim) -> pluginWithConfigType list (home-manager)
  mappingPlugins = ps: map mappingPlugin ps;

  # Type: opt -> pluginUserConfigType list (rokka.nvim) -> pluginWithConfigType list (home-manager)
  mappingPluginsWithOptimize = opt: ps:
    map (p: mappingPluginWithOptimize opt p) ps;
}
