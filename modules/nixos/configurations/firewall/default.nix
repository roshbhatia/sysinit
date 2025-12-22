{
  # Firewall configuration for NixOS
  # Default NixOS firewall is stateful and allows outbound connections
  networking.firewall = {
    enable = true;

    # Allow SSH from anywhere (development machine)
    allowedTCPPorts = [ 22 ];

    # Steam ports (optional - only needed if running Steam server or p2p games)
    # allowedTCPPorts = [ 22 27015 27016 ];
    # allowedUDPPorts = [ 27015 27016 ];

    # Tailscale doesn't require explicit ports (uses UDP 41641)
    # but firewall must allow outbound
  };
}
