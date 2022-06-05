{ self, nix-filter, ... }@inputs:

{ config, pkgs, lib, ... }:

with lib;

let
  rokka-util = import ./rokka-util.nix { };

  inherit (pkgs) callPackage;
  inherit (rokka-util) rokkaPluginDefault;

  cfg = config.programs.rokka-nvim;

  rokkaPluginUserConfigType = types.submodule {
    options = {

      rokka = mkOption {
        type = types.anything;
        description = "rokka (plugin).";
        default = rokkaPluginDefault.rokka;
        visible = false;
      };

      plugin = mkOption {
        type = with types; nullOr package;
        description = "plugin (plugin).";
        default = null;
      };

      enable = mkEnableOption "enable" // {
        type = with types; nullOr bool;
        description = "enable (plugin).";
        default = null;
      };

      optional = mkEnableOption "optional" // {
        type = with types; nullOr bool;
        description = "optional (plugin).";
        default = null;
      };

      startup = mkOption {
        type = with types; nullOr str;
        description = "startup (plugin).";
        default = null;
      };

      config = mkOption {
        type = with types; nullOr str;
        description = "config (plugin).";
        default = null;
      };

      depends = mkOption {
        type = with types; nullOr (listOf package);
        description = "depends (plugin).";
        default = null;
      };

      rtp = mkOption {
        type = with types; nullOr str;
        description = "rtp (plugin).";
        default = null;
      };

      as = mkOption {
        type = with types; nullOr str;
        description = "as (plugin).";
        default = null;
      };

      optimize = mkEnableOption "optimize" // {
        type = with types; nullOr bool;
        description = "optimize (plugin).";
        default = null;
      };

      delay = mkEnableOption "delay" // {
        type = with types; nullOr bool;
        description = "delay (plugin).";
        default = null;
      };

      extraPackages = mkOption {
        type = with types; nullOr (listOf package);
        description = "extraPackages (plugin).";
        default = null;
      };

    };
  };

  rokkaPluginConfigType = types.submodule {
    options = {

      rokka = mkOption {
        type = types.anything;
        description = "rokka (base).";
        default = rokkaPluginDefault.rokka;
        visible = false;
      };

      plugin = mkOption {
        type = types.package;
        description = "plugin (base).";
        default = rokkaPluginDefault.plugin;
      };

      enable = mkEnableOption "enable" // {
        description = "enable (base).";
        default = rokkaPluginDefault.enable;
      };

      optional = mkEnableOption "optional" // {
        description = "optional (base).";
        default = rokkaPluginDefault.optional;
      };

      startup = mkOption {
        type = with types; nullOr str;
        description = "startup (base).";
        default = rokkaPluginDefault.startup;
      };

      config = mkOption {
        type = with types; nullOr str;
        description = "config (base).";
        default = rokkaPluginDefault.config;
      };

      depends = mkOption {
        type = with types; listOf package;
        description = "depends (base).";
        default = rokkaPluginDefault.depends;
      };

      rtp = mkOption {
        type = with types; nullOr str;
        description = "rtp (base).";
        default = rokkaPluginDefault.rtp;
      };

      as = mkOption {
        type = with types; nullOr str;
        description = "as (base).";
        default = rokkaPluginDefault.as;
      };

      optimize = mkEnableOption "optimize" // {
        description = "optimize (base).";
        default = rokkaPluginDefault.optimize;
      };

      delay = mkEnableOption "delay" // {
        description = "delay (base).";
        default = rokkaPluginDefault.delay;
      };

      extraPackages = mkOption {
        type = with types; listOf package;
        description = "extraPackages (base).";
        default = rokkaPluginDefault.extraPackages;
      };

    };
  };

  # Type: getWithDefault :: (a | null) -> a -> a
  getWithDefault = value: defaultValue:
    if value != null then value else defaultValue;

  mkPluginConfig = userConfig:
    let baseConfig = cfg.pluginBaseConfig;
    in {
      rokka = getWithDefault userConfig.rokka baseConfig.rokka;
      plugin = getWithDefault userConfig.plugin baseConfig.plugin;
      enable = getWithDefault userConfig.enable baseConfig.enable;
      optional = getWithDefault userConfig.optional baseConfig.optional;
      startup = getWithDefault userConfig.startup baseConfig.startup;
      config = getWithDefault userConfig.config baseConfig.config;
      depends = getWithDefault userConfig.depends baseConfig.depends;
      rtp = getWithDefault userConfig.rtp baseConfig.rtp;
      as = getWithDefault userConfig.as baseConfig.as;
      optimize = getWithDefault userConfig.optimize baseConfig.optimize;
      delay = getWithDefault userConfig.delay baseConfig.delay;
      extraPackages =
        getWithDefault userConfig.extraPackages baseConfig.extraPackages;
    };

  rokkaNvim = rokkaPluginDefault // { plugin = callPackage ./rokka { }; };
  plugins = [ rokkaNvim ] ++ (map mkPluginConfig cfg.plugins);
  extraPackages = flatten (map (p: p.extraPackages) plugins);
  rokka-pack = callPackage ./rokka-pack {
    inherit plugins;
    nix-filter = nix-filter.lib;
    rokkaPluginBaseConfig = cfg.pluginBaseConfig;
  };
  rokka-init = callPackage ./rokka-init { };
in {
  options = {
    programs.rokka-nvim = {
      enable = mkEnableOption "rokka-nvim";

      extraPackages = mkOption {
        type = with types; listOf package;
        description = "Extra packages.";
        default = [ ];
        example = literalExpression ''
          [ pkgs.neovim-remote ]
        '';
      };

      plugins = mkOption {
        # TODO: support package.
        type = with types; listOf rokkaPluginUserConfigType;
        description = "Vim plugins.";
        default = [ ];
        example = literalExpression ''
          [ pkgs.vimPlugins.nerdtree ]
        '';
      };

      pluginBaseConfig = mkOption {
        type = rokkaPluginConfigType;
        description = "base config.";
        default = rokkaPluginDefault;
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
    };
  };

  config = mkIf cfg.enable {
    xdg.configFile = {
      "nvim/init.vim".text = mkAfter ''
        " rokka-nvim
        set packpath^=${rokka-pack}
        lua require 'init-rokka'
      '';
      "nvim/lua/init-rokka.lua".text = rokka-init.makeRokkaInit {
        inherit plugins;
        config = {
          log_plugin = "rokka.nvim";
          log_level = cfg.logLevel;

          loader_delay_time = cfg.delayTime;
        };
      };
    };
  };
}
