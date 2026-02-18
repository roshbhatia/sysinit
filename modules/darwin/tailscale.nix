{
  lib,
  config,
  ...
}:

let
  tailscaleEnabled = config.sysinit.darwin.tailscale.enable;
in
{
  services.tailscale.enable = lib.mkIf tailscaleEnabled true;
}
