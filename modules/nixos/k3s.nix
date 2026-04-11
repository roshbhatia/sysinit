# K3s single-node cluster with NVIDIA GPU passthrough
{
  pkgs,
  ...
}:

{
  # K3s server
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

  # NVIDIA container toolkit for GPU passthrough
  hardware.nvidia-container-toolkit.enable = true;

  # Ensure k3s can use the nvidia runtime
  environment.systemPackages = with pkgs; [
    kubectl
    k3s
  ];

  # Open k3s API server port
  networking.firewall.allowedTCPPorts = [ 6443 ];
}
