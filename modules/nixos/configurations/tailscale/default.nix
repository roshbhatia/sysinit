{
  pkgs,
  values,
  ...
}:
{
  environment.systemPackages = [ pkgs.tailscale ];

  services.tailscale = {
    inherit (values.tailscale) enable;
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
