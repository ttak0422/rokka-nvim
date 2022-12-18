{ lib
, vimUtils
, pluginDependsFile
, loadDelayPluginsFile
, eventsFile
, eventPluginsFiles
, ftsFile
, ftPluginsFile
, cmdsFile
, cmdPluginsFile
}:
let
  inherit (lib) concatStringsSep;
  inherit (lib.attrsets) mapAttrsToList;
  concatN = concatStringsSep "\n";
in
vimUtils.buildVimPlugin {
  pname = "rokka.nvim";
  version = "0.4.0";
  src = ./.;
  preInstall = ''
    cp ${pluginDependsFile} ./lua/rokka/gen/depends.lua
    cp ${loadDelayPluginsFile} ./lua/rokka/gen/delay.lua
    cp ${eventsFile} ./lua/rokka/gen/events.lua
  '' + (concatN (map
    ({ event, package }: ''
      cp ${package} ./lua/rokka/gen/event/${event}.lua
    '')
    eventPluginsFiles)) + ''
    cp ${ftsFile} ./lua/rokka/gen/fts.lua
  '' + (concatN (map
    ({ ft, package }: ''
      cp ${package} ./lua/rokka/gen/ft/${ft}.lua
    '')
    ftPluginsFile)) + ''
    cp ${cmdsFile} ./lua/rokka/gen/cmds.lua
  '' + (concatN (map
    ({ cmd, package }: ''
      cp ${package} ./lua/rokka/gen/cmd/${cmd}.lua
    '')
    cmdPluginsFile));
  preferLocalBuild = true;
}
