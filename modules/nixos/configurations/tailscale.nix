{
  pkgs,
  values,
  ...
}:
# =============================================================
#
# Tailscale - Your own private network(VPN) using WireGuard
#
# Open source and free for personal use. Easy setup and great client coverage
# for Linux, Windows, Mac, Android, and iOS.
#
# How to use:
#  1. Create account at https://login.tailscale.com
#  2. Login: `tailscale login`
#  3. Join network: `tailscale up --accept-routes`
#  4. For automatic connection, use authKeyFile option
#
# Status:
#   View logs: `journalctl -u tailscaled`
#   Data stored in /var/lib/tailscale (persists across reboots)
#
# References:
# https://github.com/NixOS/nixpkgs/blob/nixos-25.11/nixos/modules/services/networking/tailscale.nix
#
# =============================================================
{
  environment.systemPackages = [ pkgs.tailscale ];

  services.tailscale = {
    enable = values.tailscale.enable;
    port = 41641;
    interfaceName = "tailscale0";
    openFirewall = true;
    useRoutingFeatures = "client";
    extraSetFlags = [
      "--accept-routes"
      "--netfilter-mode=nodivert"
    ];
  };
}
