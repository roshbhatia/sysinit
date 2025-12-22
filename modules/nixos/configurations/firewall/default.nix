{
  networking.firewall = {
    enable = true;

    # SSH, Steam p2p
    allowedTCPPorts = [
      22
      27015
      27016
    ];
    allowedUDPPorts = [
      27015
      27016
    ];

    # Tailscale (UDP 41641) is handled by Tailscale service
    # mDNS/Avahi (UDP 5353) is handled by avahi service
  };
}
