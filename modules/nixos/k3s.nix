{
  pkgs,
  ...
}:

{
  services.k3s = {
    enable = true;
    role = "server";
    extraFlags = builtins.concatStringsSep " " [
      "--write-kubeconfig-mode=0644"
      "--tls-san=arrakis"
      # Add your Tailscale FQDN here, e.g.:
      # "--tls-san=arrakis.stork-eel.ts.net"
    ];
  };

  hardware.nvidia-container-toolkit.enable = true;

  environment.systemPackages = with pkgs; [
    kubectl
    k3s
  ];

  networking.firewall.allowedTCPPorts = [ 6443 ];
}
