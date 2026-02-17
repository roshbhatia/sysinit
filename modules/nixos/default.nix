# NixOS configuration entry point
{ ... }:

{
  imports = [
    # Shared modules (available at system level)
    ../shared/lib/modules/user.nix
    ../shared/lib/modules/theme.nix
    ../home/configurations/git/options.nix
    ./configurations
  ];
}
