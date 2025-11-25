{
  config,
  lib,
  pkgs,
  ...
}:
{
  # Enable Tailscale
  services.tailscale = {
    enable = true;
    package = pkgs.tailscale;
  };

  # Enable Docker
  virtualisation.docker = {
    enable = true;
    enableOnBoot = true;
  };

  # Enable OpenSSH
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
    };
  };

  # Enable automatic updates (optional, can be disabled per-host)
  system.autoUpgrade = {
    enable = lib.mkDefault false;
    allowReboot = lib.mkDefault false;
  };
}
