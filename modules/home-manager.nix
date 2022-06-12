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
    name = null;
    startup = null;
    config = null;
    depends = [ ];
    rtp = null;
    as = null;
    events = [ ];
    fileTypes = [ ];
    commands = [ ];
    delay = false;
    optimize = true;
    extraPackages = [ ];
  };

  pluginUserConfigType = types.submodule {
    options = {
      rokka = mkOption {
        type = types.anything;
        description = "for type comparison.";
        default = pluginConfigDefault.rokka;
        visible = false;
      };

      plugin = mkOption {
        type = types.package;
        description = "plugin.";
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
        # TODO: support other type.
        # TODO: support after option.
        type = with types; listOf package;
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

      delay = mkEnableOption "delay" // {
        description = "delay.";
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
        ];
      };
    });

  normalizePlugin = p:
    if p ? rokka then
      p // { name = if p.as != null then p.as else p.plugin.pname; }
    else
      pluginConfigDefault // {
        plugin = p;
        name = p.pname;
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
    in uniqueWith (p: p.name) (flatten (f plugins'));

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
    ps1 = filter (p: p.enable) cfg.plugins;
    ps2 = map normalizePlugin ps1;
    ps3 = map (p:
      if !p.optional then p else p // { plugin = optimizePackage p.plugin; })
      ps2;
  in [ rokkaNvim ] ++ ps3;
  allPlugins = flattenPlugins plugins;
  allStartPlugins = filter (p: !p.optional) allPlugins;
  allOptPlugins =
    filter (p: p.optional && !(elemWith (p': p'.name) p allStartPlugins))
    allPlugins;
  allEventPlugins = filter (p: p.events != [ ]) allOptPlugins;
  allCmdPlugins = filter (p: p.commands != [ ]) allOptPlugins;
  allFtPlugins = filter (p: p.commands != [ ]) allPlugins;

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

  rokka-pack = callPackage ./rokka-pack { inherit allPlugins; };
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
        # TODO: support package.
        type = with types; listOf pluginUserConfigType;
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
