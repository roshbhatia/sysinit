{
  values,
  lib,
  ...
}:

{
  # Hostname from values
  networking.hostName = values.hostname;

  # Lima state version (matches nixos-lima image)
  system.stateVersion = lib.mkForce "25.11";
}
