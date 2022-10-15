{ vimUtils }:
vimUtils.buildVimPlugin {
  pname = "dummy2";
  version = "0.0.1";
  src = ./.;
  preferLocalBuild = true;
}
