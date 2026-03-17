{ lib, values, ... }:

{
  imports = [
    ./common
    ../home/programs/git/options.nix
    ../shared/options/theme.nix
    ../shared/options/user.nix
  ]
  ++ lib.optional (values.lima or false) ./lima
  ++ lib.optional (values.desktop or false) ./desktop
  ++ lib.optional (values.desktop or false) ./k3s.nix;
}
