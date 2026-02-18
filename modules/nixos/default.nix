# NixOS configuration entry point
{ ... }:

{
  imports = [
    # Shared modules (available at system level)
    ../options/user.nix
    ../options/theme.nix
    ../home/programs/git/options.nix

    # System packages and configurations
    ./configurations
  ];
}
