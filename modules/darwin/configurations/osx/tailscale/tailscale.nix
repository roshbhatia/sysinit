{
  lib,
  values,
  pkgs,
  ...
}:

{
  services.tailscale = lib.mkIf values.tailscale.enable {
    enable = true;
    package = pkgs.tailscale;
  };
}

