{ vimUtils }:
vimUtils.buildVimPlugin {
  pname = "dummy3";
  version = "0.0.1";
  src = ./.;
  preferLocalBuild = true;
}
