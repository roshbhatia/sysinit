{ lib, values, ... }:

{
  imports = [
    ./common
  ]
  ++ lib.optional values.isLima ./lima
  ++ lib.optional values.isDesktop ./desktop
  ++ lib.optional values.isDesktop ./k3s.nix;
}
