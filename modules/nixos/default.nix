{ ... }:

{
  imports = [
    # Shared modules (available at system level)
    ../shared/options/user.nix
    ../shared/options/theme.nix
    ../home/programs/git/options.nix

    # System packages and configurations
    ./configurations
  ];
}
