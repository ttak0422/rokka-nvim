{ vimUtils }:
vimUtils.buildVimPlugin {
  pname = "rokka.nvim";
  version = "0.3.0";
  src = ./.;
  preferLocalBuild = true;
}
