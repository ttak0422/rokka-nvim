{ vimUtils }:
vimUtils.buildVimPlugin {
  pname = "rokka.nvim";
  version = "0.2.0";
  src = ./.;
  preferLocalBuild = true;
}
