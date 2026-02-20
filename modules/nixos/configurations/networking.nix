# Networking: NetworkManager, firewall, Tailscale, Avahi
_:

{
  # NetworkManager with systemd-resolved
  networking.networkmanager = {
    enable = true;
    dns = "systemd-resolved";
  };

  environment.enableAllTerminfo = true;

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
