{ self, nix-filter, ... }@inputs:

{ config, pkgs, lib, ... }:

with lib;

let
  inherit (builtins) map;
  inherit (pkgs) callPackage;
  inherit (lib) flatten filter;
  inherit (import ./util.nix lib) uniqueWith elemWith expandWith;

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

  normalizePlugin = p:
    if p ? rokka then
      p // { pname = if p.as != null then p.as else p.plugin.pname; }
    else
      pluginConfigDefault // {
        plugin = p;
        pname = p.pname;
      };

  flattenPlugins = plugins:
    let
      plugins' = map normalizePlugin plugins;
      f = ps:
        map (p:
          if p.depends == [ ] then
            [ p ]
          else
            let
              depends' = map normalizePlugin p.depends;
              p' = p // { depends = depends'; };
            in [ p' ] ++ depends') ps;
    in uniqueWith (p: p.pname) (flatten (f plugins'));

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

  rokkaNvim = pluginConfigDefault // { plugin = callPackage ./rokka { }; };

  plugins = let
    ps1 = map normalizePlugin cfg.plugins;
    ps2 = filter (p: p.enable) ps1;
  in [ rokkaNvim ] ++ ps2;
  allPlugins = flattenPlugins plugins;
  allStartPlugins = filter (p: !p.optional) allPlugins;
  allOptPlugins =
    filter (p: p.optional && !(elemWith (p': p'.pname) p allStartPlugins))
    allPlugins;
  allEventPlugins = filter (p: p.events != [ ]) allOptPlugins;
  allCmdPlugins = filter (p: p.commands != [ ]) allOptPlugins;
  allFtPlugins = filter (p: p.commands != [ ]) allOptPlugins;

  optPlugins = map optimizeDepends (filter (p: p.optional) plugins);

  eventPlugins = let
    plugins' = filter (p: p.events != [ ]) allOptPlugins;
    f = expandWith (x: x.events) (src: e: src // { event = e; });
  in flatten (map f plugins');
  commandPlugins = let
    plugins' = filter (p: p.commands != [ ]) allOptPlugins;
    f = expandWith (x: x.commands) (src: c: src // { command = c; });
  in flatten (map f plugins');
  fileTypePlugins = let
    plugins' = filter (p: p.fileTypes != [ ]) allOptPlugins;
    f = expandWith (x: x.fileTypes) (src: ft: src // { fileType = ft; });
  in flatten (map f plugins');

  rokka-pack = callPackage ./rokka-pack { inherit nix-filter allPlugins; };
  rokka-init = callPackage ./rokka-init {
    inherit plugins optPlugins allPlugins allStartPlugins allOptPlugins
      eventPlugins commandPlugins fileTypePlugins;
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
        set packpath^=${rokka-pack}
        set runtimepath^=${rokka-pack}
        runtime! ftdetect/**/*.vim
        runtime! ftdetect/**/*.lua
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
