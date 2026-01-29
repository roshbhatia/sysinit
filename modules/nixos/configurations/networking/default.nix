# Networking: NetworkManager, firewall, Tailscale, Avahi
_:

{
  # NetworkManager with systemd-resolved
  networking.networkmanager = {
    enable = true;
    dns = "systemd-resolved";
  };

  environment.enableAllTerminfo = true;

  # Firewall
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [
      22
      27015
      27016
    ]; # SSH, Steam P2P
    allowedUDPPorts = [
      27015
      27016
    ];
  };

  # Tailscale VPN
  services.tailscale = {
    enable = true;
    port = 41641;
    interfaceName = "tailscale0";
    openFirewall = true;
    useRoutingFeatures = "client";
    extraSetFlags = [
      "--accept-routes"
      "--netfilter-mode=nodivert"
    ];
  };

  # Avahi/mDNS for local discovery
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    publish = {
      enable = true;
      addresses = true;
      domain = true;
      hinfo = true;
      userServices = true;
      workstation = true;
    };
  };
}
