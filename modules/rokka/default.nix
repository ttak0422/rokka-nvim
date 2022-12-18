{ vimUtils, loadDelayPluginsFile }:
vimUtils.buildVimPlugin {
  pname = "rokka.nvim";
  version = "0.4.0";
  src = ./.;
  preInstall = ''
    cp ${loadDelayPluginsFile} ./lua/rokka/gen/delay.lua
  '';
  preferLocalBuild = true;
}
