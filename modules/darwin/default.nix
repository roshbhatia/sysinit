{ pkgs, lib, inputs, ... }: {
  # Import darwin-specific configs
  imports = [
    ./system.nix
    ./apps.nix
  ];
}
