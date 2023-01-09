{ pkgs, lib, nix-filter, ... }:

let
  inherit (builtins) map length;
  inherit (pkgs) callPackage writeText;
  inherit (lib) concatStringsSep filter;
  inherit (lib.attrsets) mapAttrsToList;
  inherit (import ./util.nix lib)
    toLuaTableWith toLuaTable indexed indexOf';
  concatC = concatStringsSep ",";
  concatN = concatStringsSep "\n";

  /**
   * Type:
   *   pluginUserConfigType (rokka.nvim) -> pluginWithConfigType (home-manager)
   * Doc:
   *   mapping plugin's config.
   * Note:
   *   some options are missing and have to configure elsewhere.
   */
  mappingPlugin = p: {
    plugin = p.plugin;
    optional = p.optional;
  };

  /**
   * Type:
   *   opt -> pluginUserConfigType (rokka.nvim) -> pluginWithConfigType (home-manager)
   * Doc:
   *   mapping plugin's config with optimize.
   * Note:
   *   some options are missing and have to configure elsewhere.
   */
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

  # Type: [{ idx: int, val: str }] -> pluginUserConfigType -> str
  makeOptPluginConfig = indexedOptPluginNames: p:
    let
      toIndex = pname: indexOf' (x: x.val == pname) indexedOptPluginNames;
      toIndexStr = pname: "${toString (toIndex pname)}";
      depends =
        if length (p.depends) > 0 then
          "{${concatC (map (p': toIndexStr p'.pname) p.depends)}}"
        else
          "0";
      dependsAfter =
        if length (p.dependsAfter) > 0 then
          "{${concatC (map (p': toIndexStr p'.pname) p.dependsAfter)}}"
        else
          "0";

    in
    if depends == "0" && dependsAfter == "0" then
      "0"
    else
      "{${depends},${dependsAfter}}";

  # Type: [{ idx: int, val: str }] -> [pluginUserConfigType] -> str
  makeOptPluginsConfig' = indexedOptPluginNames: ps:
    let
      optPluginConfigs =
        let
          configs = map
            (p: {
              name = p.pname;
              value = makeOptPluginConfig indexedOptPluginNames p;
            })
            ps;
        in
        filter (x: x.value != "0") configs;
    in
    "{${concatC (map (x: "['${x.name}']=${x.value}") optPluginConfigs)}}";

  # Type: obj -> package
  makeConfigFiles = { optPlugins, delayPlugins, ... }:
    callPackage ./rokka-config {
      pluginsConfigs = optPlugins;
      delayPlugins = delayPlugins;
    };

  # Type: [{ idx: int, val: str }] -> { name: string, value: [str] } -> str
  makeKvpConfig' = indexedOptPluginNames: ps:
    let
      toIndex = pname: indexOf' (x: x.val == pname) indexedOptPluginNames;
      toIndexStr = pname: "${toString (toIndex pname)}";
    in
    "{${
      concatC (mapAttrsToList
        (name: value: "['${name}']=${toLuaTable (map (x: toIndexStr x) value)}")
        ps)
    }}";

  # Type: obj -> str
  makePluginsConfigLua = cfg:
    let
      # Type: [str]
      optPluginNames = map (x: x.pname) cfg.optPlugins;
      # Type: [{ idx: int, val: str }]
      indexedOptPluginNames = indexed optPluginNames;
      # Type: str
      optPluginNamesTable = toLuaTableWith (p: "'${p}'") optPluginNames;
      initParams = [
        "log_level='${cfg.log_level}'"
        "config_root='${makeConfigFiles cfg}'"
        "opt_plugin_names=${optPluginNamesTable}"
        "opt_plugins=${makeOptPluginsConfig' indexedOptPluginNames cfg.optPlugins}"
        "mod_ps=${makeKvpConfig' indexedOptPluginNames cfg.modulePlugins}"
        "ev_ps=${makeKvpConfig' indexedOptPluginNames cfg.eventPlugins}"
        "cmd_ps=${makeKvpConfig' indexedOptPluginNames cfg.cmdPlugins}"
        "ft_ps=${makeKvpConfig' indexedOptPluginNames cfg.ftPlugins}"
        "loader_delay_time=${toString cfg.loader_delay_time}"
        "log_plugin='${cfg.log_plugin}'"
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
