{ vimUtils }:
vimUtils.buildVimPlugin {
  pname = "dummy";
  version = "0.0.1";
  src = ./.;
  preferLocalBuild = true;
}

