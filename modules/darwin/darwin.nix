{ pkgs, lib, inputs, ... }: {
  imports = [
    ./system.nix
    ./homebrew.nix
    ./homebrew-config.nix
    ./colima.nix
    inputs.nix-homebrew.darwinModules.nix-homebrew
  ];
}