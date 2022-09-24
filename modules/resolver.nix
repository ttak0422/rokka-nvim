# Generate
{ pkgs, lib, ... }:

let
  inherit (builtins) map;
  inherit (pkgs) writeText;
  inherit (lib) flatten filter;
  inherit (lib.lists) groupBy' unique foldl';
  inherit (lib.attrsets) attrValues mapAttrsToList;
  inherit (import ./util.nix lib) mergeElement expandWith;
  inherit (import ./types.nix { inherit lib; }) pluginUserConfigDefault;
in rec {
  # Type: (package | pluginUserConfigType) -> pluginUserConfigType
  normalizePlugin = p:
    if p ? rokka then
      p // { pname = if p.pname == null then p.plugin.pname else p.pname; }
    else {
      rokka = pluginUserConfigDefault.rokka;
      plugin = p;
      enable = pluginUserConfigDefault.enable;
      optional = pluginUserConfigDefault.optional;
      pname = p.pname;
      startup = pluginUserConfigDefault.startup;
      config = pluginUserConfigDefault.config;
      depends = pluginUserConfigDefault.depends;
      dependsAfter = pluginUserConfigDefault.dependsAfter;
      events = pluginUserConfigDefault.events;
      fileTypes = pluginUserConfigDefault.fileTypes;
      commands = pluginUserConfigDefault.commands;
      delay = pluginUserConfigDefault.delay;
      optimize = pluginUserConfigDefault.optimize;
      extraPackages = pluginUserConfigDefault.extraPackages;
    };

  # Type:
  #   (package | pluginUserConfigType) list -> pluginUserConfigType list
  # Note:
  #   works recursive
  normalizePlugins = ps:
    let
      # pluginUserConfigType -> pluginUserConfigType
      f = p:
        let
          p' = normalizePlugin p;
          depends' = normalizePlugins p'.depends;
          dependsAfter' = normalizePlugins p'.dependsAfter;
        in p' // {
          depends = depends';
          dependsAfter = dependsAfter';
        };
    in map f ps;

  # Type: pluginUserConfigType -> pluginUserConfigType -> pluginUserConfigType
  mergePlugin = p1: p2:
    if p1.pname != null && p2.pname != null && p1.pname != p2.pname then
      throw "Unable to merge `${p1.pname}` and `${p2.pname}` configs!"
    else
      let
        name = p1.pname;
        plugin = if p1.plugin != null then p1.plugin else p2.plugin;
        pname = if p1.pname != null then p1.pname else p2.pname;

      in p1 // {
        inherit plugin pname;
        enable = mergeElement p1.enable p2.enable pluginUserConfigDefault.enable
          "enable (${name})";
        optional =
          mergeElement p1.optional p2.optional pluginUserConfigDefault.optional
          "optional (${name})";
        startup =
          mergeElement p1.startup p2.startup pluginUserConfigDefault.startup
          "startup (${name})";
        config = mergeElement p1.config p2.config pluginUserConfigDefault.config
          "config (${name})";
        comment =
          mergeElement p1.comment p2.comment pluginUserConfigDefault.comment
          "comment (${name})";
        depends =
          mergeElement p1.depends p2.depends pluginUserConfigDefault.depends
          "depends (${name})";
        dependsAfter = mergeElement p1.dependsAfter p2.dependsAfter
          pluginUserConfigDefault.dependsAfter "dependsAfter (${name})";
        events = mergeElement p1.events p2.events pluginUserConfigDefault.events
          "events (${name})";
        fileTypes = mergeElement p1.fileTypes p2.fileTypes
          pluginUserConfigDefault.fileTypes "fileTypes (${name})";
        commands =
          mergeElement p1.commands p2.commands pluginUserConfigDefault.commands
          "commands (${name})";
        delay = mergeElement p1.delay p2.delay pluginUserConfigDefault.delay
          "delay (${name})";
        optimize =
          mergeElement p1.optimize p2.optimize pluginUserConfigDefault.optimize
          "optimize (${name})";
        extraPackages = mergeElement p1.extraPackages p2.extraPackages
          pluginUserConfigDefault.extraPackages "extraPackages (${name})";
      };

  # Type: pluginUserConfigType list -> pluginUserConfigType
  flattenPlugins = ps:
    let
      f = p:
        if p.depends == [ ] && p.dependsAfter == [ ] then
          [ p ]
        else if p.depends == [ ] then
          [ p ] ++ (flattenPlugins p.dependsAfter)
        else if p.dependsAfter == [ ] then
          [ p ] ++ (flattenPlugins p.depends)
        else
          [ p ] ++ (flattenPlugins p.dependsAfter)
          ++ (flattenPlugins p.depends);
    in flatten (map f ps);

  # Type: pluginUserConfigType list -> pluginUserConfigType list
  aggregatePlugins = ps:
    attrValues
    (groupBy' (acc: x: mergePlugin acc x) pluginUserConfigDefault (x: x.pname)
      ps);

  # Type: pluginUserConfigType list -> obj
  resolvePlugins = ps:
    let
      activePs = filter (p: p.enable) ps;
      normalizedPs = normalizePlugins activePs;
      flattenPs = flattenPlugins normalizedPs;
      allPlugins = aggregatePlugins flattenPs;
      allStartPlugins = filter (p: !p.optional) allPlugins;
      allOptPlugins = filter (p: p.optional) allPlugins;
      allEventPlugins = let
        ps = filter (p: p.events != [ ]) allOptPlugins;
        f = expandWith (x: x.events) (x: ev: x // { event = ev; });
      in groupBy' (acc: x: acc ++ [ x.pname ]) [ ] (x: x.event)
      (flatten (map f ps));
      allCmdPlugins = let
        ps = filter (p: p.commands != [ ]) allOptPlugins;
        f = expandWith (x: x.commands) (x: cmd: x // { command = cmd; });
      in groupBy' (acc: x: acc ++ [ x.pname ]) [ ] (x: x.command)
      (flatten (map f ps));
      allFtPlugins = let
        ps = filter (p: p.fileTypes != [ ]) allOptPlugins;
        f = expandWith (x: x.fileTypes) (x: ft: x // { fileType = ft; });
      in groupBy' (acc: x: acc ++ [ x.pname ]) [ ] (x: x.fileType)
      (flatten (map f ps));
    in {
      plugins = allPlugins;
      startPlugins = allStartPlugins;
      optPlugins = allOptPlugins;
      eventPlugins = allEventPlugins;
      cmdPlugins = allCmdPlugins;
      ftPlugins = allFtPlugins;
      delayPlugins = filter (p: p.delay) allOptPlugins;
      extraPackages =
        unique (foldl' (acc: x: acc ++ x.extraPackages) [ ] allPlugins);
    };

}
