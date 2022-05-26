{ self, ... }@inputs:

{ config, pkgs, lib, ... }:

with lib;

let
  inherit (pkgs) callPackage;

  defaultRokkaNvimConfig = { logLevel = "warn"; };

  defaultRokkaPluginConfig = {
    plugin = null;
    opt = false;
    init = "";
    onLoad = "";
    rtp = "";
    as = "";
  };

  cfg = config.programs.rokka-nvim;

  rokka-nvim = defaultRokkaPluginConfig // {
    plugin = callPackage ./rokka { };
    opt = true;
  };
  plugins = [ rokka-nvim ] ++ (cfg.plugins or [ ]);
  rokka-pack = callPackage ./rokka-pack { inherit plugins; };
  rokka-init = callPackage ./rokka-init { };
in {
  options = {
    programs.rokka-nvim = {
      enable = mkEnableOption "rokka-nvim";
      logLevel = mkOption {
        type = types.enum [ "trace" "debug" "info" "warn" "error" "fatal" ];
        description = "The log level of rokka.nvim";
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
