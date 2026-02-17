# NixOS configuration entry point
{ ... }:

{
  imports = [
    # Shared modules (available at system level)
    ../shared/lib/modules/user.nix
    ../home/configurations/git/options.nix
    ./configurations
  ];
}
