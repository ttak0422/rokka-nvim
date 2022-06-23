{ self, nix-filter, ... }@inputs:

{ config, pkgs, lib, ... }:

with lib;

let
  inherit (builtins) map;
  inherit (pkgs) callPackage;
  inherit (lib) flatten filter;
  inherit (lib.attrsets) attrValues;
  inherit (lib.lists) groupBy';
  inherit (import ./util.nix lib) elemWith expandWith;

  cfg = config.programs.rokka-nvim;

  pluginConfigDefault = {
    rokka = true;
    plugin = null;
    enable = true;
    optional = true;
    pname = null;
    startup = null;
    config = null;
    depends = [ ];
    rtp = null;
    as = null;
    events = [ ];
    fileTypes = [ ];
    commands = [ ];
    event = null;
    fileType = null;
    command = null;
    delay = false;
    optimize = true;
    extraPackages = [ ];
  };

  pluginUserConfigType = types.submodule {
    options = {
      rokka = mkOption {
        type = types.anything;
        description =
          "for type comparison. (Autocatically configured by rokka)";
        default = pluginConfigDefault.rokka;
        visible = false;
      };

      plugin = mkOption {
        type = types.package;
        description = "plugin.";
      };

      pname = mkOption {
        type = with types; nullOr str;
        description = "pname. (Autocatically configured by rokka)";
        default = pluginConfigDefault.pname;
        visible = false;
      };

      enable = mkEnableOption "enable" // {
        description = "enable.";
        default = pluginConfigDefault.enable;
      };

      optional = mkEnableOption "optional" // {
        description = "optional.";
        default = pluginConfigDefault.optional;
      };

      startup = mkOption {
        type = with types; nullOr str;
        description = "startup.";
        default = pluginConfigDefault.startup;
      };

      config = mkOption {
        type = with types; nullOr str;
        description = "config.";
        default = pluginConfigDefault.config;
      };

      depends = mkOption {
        type = with types; listOf (either package pluginUserConfigType);
        description = "depends.";
        default = pluginConfigDefault.depends;
      };

      rtp = mkOption {
        type = with types; nullOr str;
        description = "rtp.";
        default = pluginConfigDefault.rtp;
      };

      as = mkOption {
        type = with types; nullOr str;
        description = "as.";
        default = pluginConfigDefault.as;
      };

      events = mkOption {
        type = with types; listOf str;
        description = "events.";
        default = pluginConfigDefault.events;
      };

      commands = mkOption {
        type = with types; listOf str;
        description = "commands.";
        default = pluginConfigDefault.commands;
      };

      fileTypes = mkOption {
        type = with types; listOf str;
        description = "fileTypes.";
        default = pluginConfigDefault.fileTypes;
      };

      event = mkOption {
        type = with types; nullOr str;
        description = "event. (Autocatically configured by rokka)";
        default = pluginConfigDefault.event;
        visible = false;
      };

      command = mkOption {
        type = with types; nullOr str;
        description = "command. (Autocatically configured by rokka)";
        default = pluginConfigDefault.command;
        visible = false;
      };

      fileType = mkOption {
        type = with types; nullOr str;
        description = "fileType. (Autocatically configured by rokka)";
        default = pluginConfigDefault.fileType;
        visible = false;
      };

      delay = mkEnableOption "delay" // {
        description = "delay. (Autocatically configured by rokka)";
        default = pluginConfigDefault.delay;
      };

      optimize = mkEnableOption "optimize" // {
        description = "optimize.";
        default = pluginConfigDefault.optimize;
      };

      extraPackages = mkOption {
        type = with types; listOf package;
        description = "extraPackages.";
        default = pluginConfigDefault.extraPackages;
      };
    };
  };

  #
  # Type: (package | pluginUserConfigType) -> pluginUserConfigType
  #
  # Normalize by fill with default values.
  #
  normalizePlugin = p:
    if p ? rokka then
      p // { pname = if p.as != null then p.as else p.plugin.pname; }
    else
      pluginConfigDefault // {
        plugin = p;
        pname = p.pname;
      };

  #
  # Type: a -> a -> a -> str -> a
  #
  # Try merge element.
  #
  # Example:
  #   mergeElement 0 0 0 "foo" => 0
  #   mergeElement 1 0 0 "bar" => 1
  #   mergeElement 1 2 0 "baz" => error: Conflict `baz` value!
  #
  mergeElement = e1: e2: defaultValue: name:
    if e1 == e2 then
      e1
    else if e1 != defaultValue && e2 != defaultValue then
      throw "Conflict `${name}` value!"
    else if e1 != defaultValue then
      e1
    else
      e2;

  #
  # Type: pluginUserConfigType -> pluginUserConfigType -> pluginUserConfigType
  #
  # Try merge pluginUserConfig.
  #
  mergePluginConfig = p1: p2:
    if p1.pname != null && p2.pname != null && p1.pname != p2.pname then
      throw "Unable to merge `${p1.pname}` and `${p2.pname}` configs!"
    else
      let name = p1.pname;
      in p1 // {
        rokka = mergeElement p1.rokka p2.rokka pluginConfigDefault.rokka
          "rokka (${name})";
        plugin = mergeElement p1.plugin p2.plugin pluginConfigDefault.plugin
          "plugin (${name})";
        enable = mergeElement p1.enable p2.enable pluginConfigDefault.enable
          "enable (${name})";
        optional =
          mergeElement p1.optional p2.optional pluginConfigDefault.optional
          "optional (${name})";
        pname = mergeElement p1.pname p2.pname pluginConfigDefault.pname
          "pname (${name})";
        startup = mergeElement p1.startup p2.startup pluginConfigDefault.startup
          "startup (${name})";
        config = mergeElement p1.config p2.config pluginConfigDefault.config
          "config (${name})";
        depends = mergeElement p1.depends p2.depends pluginConfigDefault.depends
          "depends (${name})";
        rtp =
          mergeElement p1.rtp p2.rtp pluginConfigDefault.rtp "rtp (${name})";
        as = mergeElement p1.as p2.as pluginConfigDefault.as "as (${name})";
        events = mergeElement p1.events p2.events pluginConfigDefault.events
          "events (${name})";
        fileTypes =
          mergeElement p1.fileTypes p2.fileTypes pluginConfigDefault.fileTypes
          "fileTypes (${name})";
        commands =
          mergeElement p1.commands p2.commands pluginConfigDefault.commands
          "commands (${name})";
        delay = mergeElement p1.delay p2.delay pluginConfigDefault.delay
          "delay (${name})";
        optimize =
          mergeElement p1.optimize p2.optimize pluginConfigDefault.optimize
          "optimize (${name})";
        extraPackages = mergeElement p1.extraPackages p2.extraPackages
          pluginConfigDefault.extraPackages "extraPackages (${name})";
      };

  #
  # Type: pluginUserConfigType list -> pluginUserConfigType list
  #
  # Flatten plugins hierarchy.
  #
  # [{ plugin = foo; depends = [{ plugin = bar; depends = [{ plugin = baz; depends = []; }]; }]; }]
  #   => [ { plugin = foo; depends = [...]; } { plugin = bar; depends = [...]; } { plugin = baz; depends = []; } ]
  #
  # Note:
  #   Plugin configurations merged automatically.
  #
  #   e.g.
  #     plugins = [ { plugin = foo; config = "-- FOO"; } { plugin = bar; depends = [ foo ]; config = "-- BAR"; } ];
  #       => When loading `bar` plugin when `foo` plugin is not loaded
  #          1. resolve `bar` dependencies.
  #            1-1. `packadd foo`.
  #            1-2. run `foo` config. (-- FOO)
  #          2. load `bar`.
  #            1-1 `packadd bar`.
  #            1-2 run `bar` config. (-- BAR)
  #
  flattenPlugins = plugins:
    let
      f = ps:
        map (p:
          if p.depends == [ ] then
            [ p ]
          else
            let
              depends' = map normalizePlugin p.depends;
              p' = p // { depends = depends'; };
            in [ p' ] ++ depends') ps;
      # normalize args.
      ps1 = map normalizePlugin plugins;
      # just flatten dependencies.
      ps2 = flatten (f ps1);
      # normalized
      ps3 = map normalizePlugin ps2;
      # aggregate configurations. Type: AttrSet[str][pluginUserConfigType]
      ps4 = groupBy' (acc: x: mergePluginConfig acc x) pluginConfigDefault
        (x: x.pname) ps3;
    in attrValues ps4;

  rokkaNvim = normalizePlugin (callPackage ./rokka { });

  # Type: pluginUserConfigType list
  plugins = let
    ps1 = map normalizePlugin cfg.plugins;
    ps2 = filter (p: p.enable) ps1;
  in [ rokkaNvim ] ++ ps2;
  allPlugins = flattenPlugins plugins;
  allStartPlugins = filter (p: !p.optional) allPlugins;

  #
  # Type: pluginUserConfigType -> bool
  #
  # Check if the plugin exists only in `opt`.
  #
  optOnly = plugin: !(elemWith (p: p.pname) plugin allStartPlugins);

  #
  # Type: pluginUserConfigType -> bool
  #
  allOptPlugins = filter (p: p.optional && optOnly p) allPlugins;
  allEventPlugins = filter (p: p.events != [ ]) allOptPlugins;
  allCmdPlugins = filter (p: p.commands != [ ]) allOptPlugins;
  allFtPlugins = filter (p: p.commands != [ ]) allOptPlugins;

  #
  # Type: (package | pluginUserConfigType) -> pluginUserConfigType
  #
  # Optimize plugin dependencies.
  #
  # Example:
  #   allStartPlugins = [{ plugin = foo; optional = false; }]
  #   optimizeDepends { plugin = bar; depends = [ foo bar ]; }]
  #     => { plugin = bar; depends = [ bar ]; }
  #
  optimizeDepends = plugin:
    let
      plugin' = normalizePlugin plugin;
      f = p:
        if p.depends == [ ] then
          p
        else
          let depends' = map f (map normalizePlugin (filter optOnly p.depends));
          in p // { depends = depends'; };
    in f plugin';

  optPlugins = map optimizeDepends (filter (p: p.optional) plugins);

  # Type: pluginUserConfigType list
  eventPlugins = let
    plugins' = filter (p: p.events != [ ]) allOptPlugins;
    f = expandWith (x: x.events) (src: e: src // { event = e; });
  in flatten (map f plugins');

  # Type: pluginUserConfigType list
  commandPlugins = let
    plugins' = filter (p: p.commands != [ ]) allOptPlugins;
    f = expandWith (x: x.commands) (src: c: src // { command = c; });
  in flatten (map f plugins');

  # Type: pluginUserConfigType list
  fileTypePlugins = let
    plugins' = filter (p: p.fileTypes != [ ]) allOptPlugins;
    f = expandWith (x: x.fileTypes) (src: ft: src // { fileType = ft; });
  in flatten (map f plugins');

  rokka-pack = callPackage ./rokka-pack { inherit nix-filter allPlugins; };
  rokka-init = callPackage ./rokka-init {
    inherit plugins optPlugins allPlugins allStartPlugins allOptPlugins
      eventPlugins commandPlugins fileTypePlugins;
    neovimConfig = cfg.extraConfig;
  };

  extraPackages = cfg.extraPackages
    ++ (flatten (map (p: p.extraPackages) allPlugins));
in {
  options = {
    programs.rokka-nvim = {
      enable = mkEnableOption "rokka-nvim";

      plugins = mkOption {
        type = with types; listOf (either package pluginUserConfigType);
        description = "Vim plugins.";
        default = [ ];
        example = literalExpression ''
          [ pkgs.vimPlugins.nerdtree ]
        '';
      };

      delayTime = mkOption {
        type = types.int;
        description = "used for delay loader. msec.";
        default = 100;
      };

      logLevel = mkOption {
        type = types.enum [ "trace" "debug" "info" "warn" "error" "fatal" ];
        description = "The log level of rokka.nvim.";
        default = "warn";
      };

      extraConfig = mkOption {
        type = types.lines;
        default = "";
        description = "neovim config (lua).";
      };

      extraPackages = mkOption {
        type = with types; listOf package;
        description = "extraPackages.";
        default = [ ];
      };
    };
  };

  config = mkIf cfg.enable {
    programs.neovim.extraPackages = extraPackages;
    xdg.configFile = {
      "nvim/init.vim".text = mkAfter ''
        " rokka-nvim
        set packpath^=${rokka-pack.pack}
        set runtimepath^=${rokka-pack.pack}
        runtime! ${rokka-pack.ft}/**/*.vim
        runtime! ${rokka-pack.ft}/**/*.lua
        lua require 'init-rokka'
      '';
      "nvim/lua/init-rokka.lua".text = rokka-init.makeRokkaInit {
        config = {
          log_plugin = "rokka.nvim";
          log_level = cfg.logLevel;
          loader_delay_time = cfg.delayTime;
        };
      };
    };
  };
}
