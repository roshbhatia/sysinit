{
  lib,
  values,
  pkgs,
  ...
}:

{
  services.tailscale = lib.mkIf values.darwin.tailscale.enable {
    enable = true;
    package = pkgs.tailscale;
  };
}
