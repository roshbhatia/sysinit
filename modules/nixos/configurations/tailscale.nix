{
  values,
  ...
}:

{
  services.tailscale = {
    enable = values.tailscale.enable;
    useRoutingFeatures = "both";
    extraSetFlags = [
      "--netfilter-mode=nodivert"
    ];
  };

  # Allow tailscale traffic through firewall
  networking.firewall.trustedInterfaces = [ "tailscale0" ];
  networking.firewall.allowedUDPPorts = [ 41641 ]; # Tailscale UDP port
}
