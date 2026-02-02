{
  lib,
  values,
  ...
}:

let
  tailscaleEnabled = values.darwin.tailscale.enable or true;
in
{
  services.tailscale.enable = lib.mkIf tailscaleEnabled true;
}
