{ pkgs, lib, inputs, ... }: {
  imports = [
    ./system.nix
    ./homebrew.nix
    inputs.nix-homebrew.darwinModules.nix-homebrew
  ];
}