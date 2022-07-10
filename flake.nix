{
  description = "Neovim Plugin Manager for Nix.";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    nix-filter.url = "github:numtide/nix-filter";
  };

  outputs = { self, nixpkgs, flake-utils, nix-filter, ... }@inputs:
    {
      hmModule = import ./modules/home-manager.nix
        (inputs // { nix-filter = nix-filter.lib; });
    } // flake-utils.lib.eachDefaultSystem (system:
      let pkgs = nixpkgs.legacyPackages.${system};
      in {
        devShell = pkgs.mkShell {
          buildInputs = with pkgs; [ nixfmt luaformatter pre-commit ];
        };
      });
}
