{
  lib,
  values,
  ...
}:

let
  tailscaleEnabled = values.darwin.tailscale.enable or true;
in
lib.mkIf tailscaleEnabled {
  services.tailscale.enable = true;
}
