{ self, ... }@inputs:

{ config, pkgs, lib, ... }:

with lib;

let
  inherit (pkgs) callPackage;

  cfg = config.programs.rokka-nvim;

  rokkaNvimPluginType = types.submodule {
    plugin = mkOption {
      type = types.package;
      description = "vim plugin";
    };
    enable = mkEnableOption "plugin" // { default = true; };
    opt = mkEnableOption "opt" // {
      description = ''
        opt = false; # automatic loading.
        opt = true;  # manual loading.
      '';
    };
    startup = mkOption {
      type = with types; nullOr str;
      description = "It is executed at startup of rokka.nvim.";
      default = null;
    };
    config = mkOption {
      type = with types; nullOr str;
      description = "It is executed after 'plugin' is loaded.";
      default = null;
    };
    rtp = mkOption {
      type = with types; nullOr str;
      description = "Subdirectory of 'plugin'.";
      default = null;
    };
    as = mkOption {
      type = with types; nullOr str;
      description = "Alias of 'plugin'.";
      default = null;
    };
    extraPackages = mkOption {
      type = with types; listOf package;
      description = "Nix packages.";
      default = [ ];
      example = literalExpression ''
        [ pkgs.glow ]
      '';
    };
  };

  rokka-nvim = {
    plugin = callPackage ./rokka { };
    opt = true;
  };
  plugins = [ rokka-nvim ]
    ++ (map (p: defaultRokkaPluginConfig // p) (cfg.plugins or [ ]));
  packages = flatten (map (p: p.packages) plugins);
  rokka-pack = callPackage ./rokka-pack { inherit plugins; };
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
        types = with types; oneOf [ rokkaNvimPluginType ];
        description = "Vim plugins.";
        default = [ ];
        example = literalExpression ''
          # WIP
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
