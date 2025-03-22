{ pkgs, lib, inputs, ... }: {
  imports = [
    ./system.nix
    ./homebrew.nix
    ./colima.nix
  ];
}