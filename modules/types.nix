{ lib, ... }:

let inherit (lib) types mkOption mkEnableOption;
in
rec {
  pluginUserConfigDefault = {
    rokka = null;
    plugin = null;
    enable = true;
    optional = true;
    pname = null;
    startup = null;
    config = null;
    comment = null;
    depends = [ ];
    dependsAfter = [ ];
    modules = [ ];
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
        default = null;
        visible = false;
      };

      plugin = mkOption {
        type = types.package;
        description = "plugin for vim.";
      };

      enable = mkEnableOption "enable" // {
        description = "enable plugin";
        default = pluginUserConfigDefault.enable;
      };

      optional = mkEnableOption "optional" // {
        description = ''
          optional = true;  # manage plugins as opt
          optional = false; # manage plugins as start
        '';
        default = pluginUserConfigDefault.optional;
      };

      pname = mkOption {
        type = with types; nullOr str;
        description = "plugin name";
        default = pluginUserConfigDefault.pname;
      };

      startup = mkOption {
        type = with types; nullOr lines;
        description = "configured at rokka.nvim initialized";
        default = pluginUserConfigDefault.startup;
      };

      config = mkOption {
        type = with types; nullOr lines;
        description = "configured at plugin loaded";
        default = pluginUserConfigDefault.config;
      };

      comment = mkOption {
        type = with types; nullOr lines;
        description = "plugin comment";
        default = pluginUserConfigDefault.comment;
      };

      depends = mkOption {
        type = with types; listOf (either package pluginUserConfigType);
        description = "plugin dependencies. load before this plugin.";
        default = pluginUserConfigDefault.depends;
      };

      dependsAfter = mkOption {
        type = with types; listOf (either package pluginUserConfigType);
        description = "plugin dependencies. load after this plugin.";
        default = pluginUserConfigDefault.dependsAfter;
      };

      # module = ... configured by rokka

      modules = mkOption {
        type = with types; listOf str;
        description = "modules load this plugin. (optional only)";
        default = pluginUserConfigDefault.modules;
      };

      # event = ... configured by rokka

      events = mkOption {
        type = with types; listOf str;
        description = "events load this plugin. (optional only)";
        default = pluginUserConfigDefault.events;
      };

      # fileType = ... configured by rokka

      fileTypes = mkOption {
        type = with types; listOf str;
        description = "filetypes load this plugin. (optional only)";
        default = pluginUserConfigDefault.fileTypes;
      };

      # command = ... configured by rokka

      commands = mkOption {
        type = with types; listOf str;
        description = "command load this plugin. (optional only)";
        default = pluginUserConfigDefault.commands;
      };

      delay = mkEnableOption "delay" // {
        description = "delay flag.";
        default = pluginUserConfigDefault.delay;
      };

      optimize = mkEnableOption "optimize" // {
        description = "optimzie flag.";
        default = pluginUserConfigDefault.optimize;
      };

      extraPackages = mkOption {
        type = with types; listOf package;
        description = "extraPackages.";
        default = pluginUserConfigDefault.extraPackages;
      };
    };
  };
}
