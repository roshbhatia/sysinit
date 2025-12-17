{
  lib,
  ...
}:
{
  # Disable firewall by default (can be enabled per-service)
  networking.firewall.enable = lib.mkDefault false;

  # Add terminfo database of all known terminals to the system profile
  # https://github.com/NixOS/nixpkgs/blob/nixos-25.11/nixos/modules/config/terminfo.nix
  environment.enableAllTerminfo = true;
}
