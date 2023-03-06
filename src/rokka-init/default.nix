{ pkgs, stdenv, initConfig }:
let
  inherit (stdenv) mkDerivation;
  inherit (pkgs) writeText;
  initConfigFile = writeText "initConfig.lua" initConfig;
  buildScript = writeText "batch.vim" ''
    lua << EOF
      local target_filename="${initConfigFile}"
      local out_filename="init-config"
      local chunk = assert(loadfile(target_filename))
      local file = assert(io.open(out_filename, "w+b"))
      file:write(string.dump(chunk))
      file:close()
    EOF
  '';
in
mkDerivation {
  pname = "rokka-init";
  version = "0.0.1";
  src = ./.;
  outputs = [ "out" ];
  preferLocalBuild = true;
  buildInputs = with pkgs; [ neovim ];
  buildPhase = ''
    nvim --clean -es -S ${buildScript} -V
  '';
  installPhase = ''
    cp init-config $out
  '';
}
