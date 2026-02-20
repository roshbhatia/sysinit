{ pkgs, config, ... }:

{
  imports = [
    # Shared modules (available at system level)
    ../shared/options/user.nix
    ../shared/options/theme.nix
    ../home/programs/git/options.nix

    # System configurations
    ./lima.nix
  ];
}
