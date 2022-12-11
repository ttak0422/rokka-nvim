# EXPERIMENTAL
{ self, ... }@inputs:
{ options, config, pkgs, lib, ... }:
let
  inherit (builtins) map toString length;
  inherit (pkgs) callPackage writeText;
  inherit (lib)
    types mkIf mkOption mkEnableOption mkAfter mkBefore literalExample;
  inherit (import ./types.nix { inherit lib; }) pluginUserConfigType;
  inherit (import ./resolver.nix { inherit pkgs lib; })
    normalizePlugin resolvePlugins;
  inherit (import ./wrapper.nix {
    inherit pkgs lib;
    nix-filter = inputs.nix-filter;
  })
    mappingPluginsWithOptimize makePluginsConfigLua makePluginsConfigLuaFile;

  rokkaNvim = (normalizePlugin (callPackage ./rokka { })) // {
    optional = false;
  };
  cfg = config.programs.rokka-nvim;
  plugins = resolvePlugins ([ rokkaNvim ] ++ cfg.plugins);
  rokkaConfig = {
    log_plugin = "rokka.nvim";
    log_level = cfg.logLevel;
    loader_delay_time = cfg.loaderDelayTime;
  } // plugins;
  initConfig =
    if cfg.compileInitFile then ''
      -- ${writeText "config.lua" cfg.extraConfigLua}
      -- ${makePluginsConfigLuaFile rokkaConfig}
      dofile('${
        (callPackage ./rokka-init {
          initConfig = ''
            ${cfg.extraConfigLua}
            ${makePluginsConfigLua rokkaConfig}
          '';
        })
      }')
    '' else ''
      -- extraconfig lua
      ${cfg.extraConfigLua}
      -- rokka config
      ${makePluginsConfigLua rokkaConfig}
    '';
in
{
  options.programs.rokka-nvim = {
    enable = mkEnableOption "rokka-nvim";

    logLevel = mkOption {
      type = types.enum [ "debug" "info" "warn" "error" ];
      description = "log level of rokka.nvim";
      default = "warn";
    };

    package = mkOption {
      type = types.package;
      description = "alias for nvim.package";
      default = pkgs.neovim-unwrapped;
    };

    loaderDelayTime = mkOption {
      type = types.int;
      default = 100;
      description = "time to load delay plugins";
    };

    extraConfig = mkOption {
      type = types.lines;
      default = "";
      description = "neovim configs in viml";
      example = literalExample ''
        set number
      '';
    };

    compileInitFile = mkEnableOption "compileInitFile" // {
      description = "compile init lua file.";
    };

    extraConfigLua = mkOption {
      type = types.lines;
      default = "";
      description = "neovim configs in lua";
      example = literalExample ''
        vim.wo.number=true
      '';
    };

    extraPackages = mkOption {
      type = with types; listOf package;
      description = "extraPackages";
      default = [ ];
    };

    excludePaths = mkOption {
      type = with types; listOf str;
      default = [
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

    plugins = mkOption {
      type = with types; listOf (either package pluginUserConfigType);
      description = "neovim plugins";
      default = [ ];
      example = literalExample ''
        plugins = [ pkgs.vimPlugins.nerdtree ]
      '';
    };

    withNodeJs = mkEnableOption "withNodeJs" // {
      description = "alias for nvim.withNodeJs";
    };

    withPython3 = mkEnableOption "withPython3" // {
      description = "alias for nvim.withPython3";
    };

    withRuby = mkEnableOption "withRuby" // {
      description = "alias for nvim.withRuby";
    };

  };

  config = mkIf cfg.enable {
    programs.neovim = {
      enable = true;
      package = cfg.package;
      plugins = mappingPluginsWithOptimize { excludePaths = cfg.excludePaths; }
        rokkaConfig.plugins;
      extraConfig = mkBefore ''
        ${cfg.extraConfig}
      '';
      withNodeJs = cfg.withNodeJs;
      withPython3 = cfg.withPython3;
      withRuby = cfg.withRuby;
      extraPackages = cfg.extraPackages ++ rokkaConfig.extraPackages;
    };
    xdg.configFile."nvim/init.lua".text = lib.mkAfter ''
      ${initConfig}
    '';
  };
}
