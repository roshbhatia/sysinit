{ lib, values, ... }:

{
  imports = [
    ./github-runner.nix
    ./ere-runners.nix
    ./common
  ]
  ++ lib.optional values.isDesktop ./desktop
  ++ lib.optional (values.k3s.enable or false) ./k3s.nix;
}
