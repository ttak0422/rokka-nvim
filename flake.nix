{
  description = "Neovim Plugin Manager for Nix.";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    nix-filter.url = "github:numtide/nix-filter";
    nixt = {
      url = "github:nix-community/nixt";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-utils.follows = "flake-utils";
      };
    };
  };

  outputs = { self, nixpkgs, flake-utils, nix-filter, ... }@inputs:
    {
      hmModule = import ./modules/hm-nvim-wrapper.nix inputs;
    } // flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        nixt = inputs.nixt.packages.${system}.nixt;
      in {
        devShell = pkgs.mkShell {
          buildInputs = with pkgs; [ nixfmt luaformatter pre-commit nixt ];
        };
      });
}
