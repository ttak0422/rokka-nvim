{ pkgs, lib, nix-filter, ... }:

let
  inherit (builtins) map length;
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

  # Type: str
  doConfigure = ''
    local function docfg(pname, cfg_file_path)
      local success, err_msg = pcall(dofile, cfg_file_path)
      if not success then
        err_msg = err_msg or '-- no msg --'
        logger.warn('[' .. pname .. '] configure error: ' .. err_msg)
      end
    end
  '';

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
      cfg =
        if p.config != null then
          "config=function()docfg('${p.pname}','${
          writeText p.pname p.config
        }')end,"
        else
          "";
      # { loaded: bool, config: str, opt_depends: listOf str, opt_depends_after: listOf str }
    in
    "['${p.pname}']={${cfg}${depends}${dependsAfter}}";

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
  makeExtraConfigLuaFile = cfgText: writeText "rokka-extraconfig.lua" cfgText;

  # Type: obj -> str
  makePluginsConfigLua = cfg:
    let
      initParams = [
        "log_plugin='${cfg.log_plugin}'"
        "log_level='${cfg.log_level}'"
        "loader_delay_time=${toString cfg.loader_delay_time}"
        "opt_plugins=${makeOptPluginsConfig cfg.optPlugins}"
        "loader_module_plugins=${makeKvpConfig cfg.modulePlugins}"
        "loader_event_plugins=${makeKvpConfig cfg.eventPlugins}"
        "loader_cmd_plugins=${makeKvpConfig cfg.cmdPlugins}"
        "loader_ft_plugins=${makeKvpConfig cfg.ftPlugins}"
        "loader_delay_plugins=${makeListConfig cfg.delayPlugins}"
      ];
      initParams' = concatC initParams;
    in
    ''
      local rokka = require('rokka')
      local logger = require('rokka.log')
      ${doConfigure}
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
