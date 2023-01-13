{ pkgs, lib, nix-filter, ... }:

let
  inherit (builtins) map attrNames;
  inherit (pkgs) callPackage writeText;
  inherit (lib) concatStringsSep filter;
  inherit (import ./util.nix lib) toLuaTableWith;
  concatC = concatStringsSep ",";
  concatN = concatStringsSep "\n";

  #
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

  #
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
    in concatN (map
      (p: ''
        -- ${p.pname}
        ${p.startup}
      '')
      targets);

  # Type: pluginUserConfigType list -> str
  makeStartPluginsConfig = ps:
    let targets = filter (p: p.config != null) ps;
    in concatN (map
      (p: ''
        -- ${p.pname}
        ${p.config}
      '')
      targets);

  # Type: obj -> package
  makeConfigFiles =
    { optPlugins
    , delayPlugins
    , modulePlugins
    , eventPlugins
    , cmdPlugins
    , ftPlugins
    , ...
    }:
    callPackage ./rokka-config {
      pluginsConfigs = optPlugins;
      modulePlugins = modulePlugins;
      eventPlugins = eventPlugins;
      cmdPlugins = cmdPlugins;
      ftPlugins = ftPlugins;
      delayPlugins = delayPlugins;
    };

  # Type: obj -> str
  makePluginsConfigLua = cfg:
    let
      initParams = [
        "log_level='${cfg.log_level}'"
        "log_plugin='${cfg.log_plugin}'"
        "config_root='${makeConfigFiles cfg}'"
        "delay_time=${toString cfg.loader_delay_time}"
        "mods=${toLuaTableWith (mod: "'${mod}'") (attrNames cfg.modulePlugins)}"
        "evs=${toLuaTableWith (ev: "'${ev}'") (attrNames cfg.eventPlugins)}"
        "cmds=${toLuaTableWith (cmd: "'${cmd}'") (attrNames cfg.cmdPlugins)}"
        "fts=${toLuaTableWith (ft: "'${ft}'") (attrNames cfg.ftPlugins)}"
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
{
  inherit makePluginsConfigLua makePluginsConfigLuaFile;

  # Type: pluginUserConfigType list (rokka.nvim) -> pluginWithConfigType list (home-manager)
  mappingPlugins = ps: map mappingPlugin ps;

  # Type: opt -> pluginUserConfigType list (rokka.nvim) -> pluginWithConfigType list (home-manager)
  mappingPluginsWithOptimize = opt: ps:
    map (p: mappingPluginWithOptimize opt p) ps;
}
