{
  description = "Neovim Plugin Manager for Nix.";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    nixt = {
      url = "github:nix-community/nixt";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-utils.follows = "flake-utils";
      };
    };
    pre-commit-hooks = {
      url = "github:cachix/pre-commit-hooks.nix";
      inputs = { flake-utils.follows = "flake-utils"; };
    };
  };

  outputs = { self, nixpkgs, flake-utils, pre-commit-hooks, ... }@inputs:
    {
      hmModule = import ./modules/hm-nvim-wrapper.nix inputs;
    }
    // flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        nixt = inputs.nixt.packages.${system}.nixt;
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
          buildInputs = with pkgs; [ nixt ];
          inherit (self.checks.${system}.pre-commit-check) shellHook;
        };
      });
}
