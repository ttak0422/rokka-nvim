{ self, nix-filter, ... }@inputs:

{ config, pkgs, lib, ... }:

with lib;

let
  rokka-util = import ./rokka-util.nix { };

  inherit (pkgs) callPackage;
  inherit (rokka-util) rokkaNvimPluginDefault;

  cfg = config.programs.rokka-nvim;

  rokkaNvimPluginType = types.submodule {
    options = {

      rokka = mkOption {
        type = types.anything;
        description =
          "Used to compare between rokkaPlugin and plain vim packages.";
        default = rokkaNvimPluginDefault.rokka;
        visible = false;
      };

      plugin = mkOption {
        type = types.package;
        description = "vim plugin.";
      };

      enable = mkEnableOption "plugin" // {
        default = rokkaNvimPluginDefault.enable;
      };

      optional = mkEnableOption "optional" // {
        description = ''
          optional = false; # automatic loading.
          optional = true;  # manual loading.
        '';
        default = rokkaNvimPluginDefault.optional;
      };

      startup = mkOption {
        type = with types; nullOr str;
        description = "It is executed at startup of rokka.nvim.";
        default = rokkaNvimPluginDefault.startup;
      };

      config = mkOption {
        type = with types; nullOr str;
        description = "It is executed after 'plugin' is loaded.";
        default = rokkaNvimPluginDefault.config;
      };

      depends = mkOption {
        type = with types; listOf package;
        description = "dependencies.";
        default = rokkaNvimPluginDefault.depends;
      };

      rtp = mkOption {
        type = with types; nullOr str;
        description = "Subdirectory of 'plugin'.";
        default = rokkaNvimPluginDefault.rtp;
      };

      as = mkOption {
        type = with types; nullOr str;
        description = "Alias of 'plugin'.";
        default = rokkaNvimPluginDefault.as;
      };

      optimize = mkEnableOption "optimize" // {
        description = "optimize plugin.";
        default = rokkaNvimPluginDefault.optimize;
      };

      extraPackages = mkOption {
        type = with types; listOf package;
        description = "Nix packages.";
        default = rokkaNvimPluginDefault.extraPackages;
        example = literalExpression ''
          [ pkgs.glow ]
        '';
      };

    };
  };

  rokkaNvim = rokka-util.rokkaNvimPluginDefault // {
    plugin = callPackage ./rokka { };
  };
  plugins = [ rokkaNvim ] ++ cfg.plugins;
  packages = flatten (map (p: p.packages) plugins);
  rokka-pack = callPackage ./rokka-pack {
    inherit rokka-util plugins;
    nix-filter = nix-filter.lib;
  };
  rokka-init = callPackage ./rokka-init { inherit rokka-util; };
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
        type = with types; listOf rokkaNvimPluginType;
        description = "Vim plugins.";
        default = [ ];
        example = literalExpression ''
          [ pkgs.vimPlugins.nerdtree ]
        '';
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
          log_level = cfg.logLevel or defaultRokkaNvimConfig.logLevel;
        };
      };
    };
  };
}
