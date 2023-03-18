{
  description = "Neovim Plugin Manager for Nix.";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    pre-commit-hooks = {
      url = "github:cachix/pre-commit-hooks.nix";
      inputs = { flake-utils.follows = "flake-utils"; };
    };
    nix-filter.url = "github:numtide/nix-filter";
  };

  outputs =
    { self, nixpkgs, flake-utils, pre-commit-hooks, nix-filter, ... }@inputs:
    {
      hmModule = import ./src/hm-nvim-wrapper.nix
        (inputs // { nix-filter = nix-filter.lib; });
    } // flake-utils.lib.eachDefaultSystem (system:
    let
      pkgs = import nixpkgs { inherit system; };
    in
    {
      checks = {
        pre-commit-check = pre-commit-hooks.lib.${system}.run {
          src = ./.;
          hooks = {
            nixpkgs-fmt.enable = true;
            stylua.enable = true;
          };
        };
      };
      devShell = pkgs.mkShell {
        inherit (self.checks.${system}.pre-commit-check) shellHook;
      };
    });
}
