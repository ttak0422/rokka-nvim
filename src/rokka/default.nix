{ vimUtils }:
vimUtils.buildVimPlugin {
  pname = "rokka.nvim";
  version = "0.4.0";
  src = ./.;
  preferLocalBuild = true;
}
