{ vimUtils }:
vimUtils.buildVimPlugin {
  pname = "rokka.nvim";
  version = "0.1.0";
  src = ./.;
  preferLocalBuild = true;
}
