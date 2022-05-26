{
  description = "[WIP] Neovim Plugin Manager for Nix.";

  inputs = { nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable"; };

  outputs = { self, nixpkgs, ... }@inputs: {
    hmModule = import ./modules/home-manager.nix inputs;
  };
}
