{ pkgs, lib, inputs, ... }: {
  imports = [
    ./system.nix
    ./homebrew.nix
    ./colima.nix
    ./npm.nix
    ./pipx.nix
    inputs.nix-homebrew.darwinModules.nix-homebrew
  ];
}