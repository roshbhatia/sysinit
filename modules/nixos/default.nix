{ lib, values, ... }:

{
  imports = [
    ./github-runner.nix
    ./ere-runners.nix
    ./common
  ]
  ++ lib.optional values.isDesktop ./desktop
  ++ lib.optional values.isDesktop ./k3s.nix;
}
