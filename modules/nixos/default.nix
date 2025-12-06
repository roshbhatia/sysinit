{ values, ... }:

{
  imports = [
    ./configurations
  ];

  # Common NixOS settings across all hosts
  system.stateVersion = "24.11";

  # Hostname from centralized config
  networking.hostName = values.user.hostname;
}
