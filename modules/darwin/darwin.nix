{ pkgs, lib, inputs, ... }: {
  imports = [
    ./system.nix
    ./homebrew.nix
    ./colima.nix
    inputs.nix-homebrew.darwinModules.nix-homebrew
  ];
}