{
  description = "Neovim Plugin Manager for Nix.";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nix-filter.url = "github:numtide/nix-filter";
    nixt = {
      url = "github:nix-community/nixt";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-utils.follows = "flake-utils";
      };
    };
  };

  outputs = { self, nixpkgs, nix-filter, ... }@inputs: {
    hmModule = import ./modules/hm-nvim-wrapper.nix inputs;
  };
}
