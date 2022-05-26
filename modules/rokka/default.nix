{ vimUtils }:
vimUtils.buildVimPlugin {
  pname = "rokka.nvim";
  version = "0.0.1-alpha";
  src = ./.;
  preferLocalBuild = true;
}
