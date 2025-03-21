{ pkgs, lib, inputs, ... }: {
  # Import darwin-specific configs
  imports = [
    ./system.nix
    ./homebrew/default.nix
  ];
}