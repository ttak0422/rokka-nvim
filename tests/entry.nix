{ pkgs ? import <nixpkgs> { } }:
let
  inherit (pkgs) callPackage;
  inherit (pkgs.lib) runTests;
  utilSpec = callPackage ./util.spec.nix { };
  wrapperSpec = callPackage ./wrapper.spec.nix { };
  resolverSpec = callPackage ./resolver.spec.nix { };
in
runTests (utilSpec // wrapperSpec // resolverSpec)
