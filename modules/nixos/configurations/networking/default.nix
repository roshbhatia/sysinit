{
  config,
  lib,
  values,
  ...
}:
{
  networking = {
    hostName = values.user.hostname;

    # Use NetworkManager for network management
    networkmanager.enable = lib.mkDefault true;

    # Enable firewall
    firewall = {
      enable = lib.mkDefault true;
      # Allow common ports (can be overridden per-host)
      allowedTCPPorts = lib.mkDefault [ ];
      allowedUDPPorts = lib.mkDefault [ ];
    };

    # Enable Tailscale
    # Configured in services module
  };

  # Set hostname
  environment.etc."hostname".text = values.user.hostname;
}
