{
  config,
  pkgs,
  lib,
  ...
}:
{
  # urth - Home Server (x86_64-linux)
  # Ubuntu server being migrated to NixOS with k3s

  # Server configuration - no desktop environment
  # Running headless

  # Enable k3s (lightweight Kubernetes)
  services.k3s = {
    enable = true;
    role = "server";
    extraFlags = toString [
      "--write-kubeconfig-mode=644"
      "--disable=traefik" # Disable traefik if you want to use ingress-nginx
    ];
  };

  # Open k3s required ports
  networking.firewall = {
    allowedTCPPorts = [
      6443 # k3s API server
      10250 # kubelet
    ];
    allowedUDPPorts = [
      8472 # k3s flannel VXLAN
    ];
  };

  # Server-specific packages
  environment.systemPackages = with pkgs; [
    # Kubernetes tools
    kubectl
    kubernetes-helm
    k9s

    # Container tools
    docker-compose
    dive # Docker image explorer

    # Monitoring
    htop
    btop
    iotop

    # Network tools
    nmap
    tcpdump
    iperf3
  ];

  # Enable container runtime for k3s
  virtualisation.docker = {
    enable = true;
    enableOnBoot = true;
  };

  # Automatic cleanup of old containers
  virtualisation.docker.autoPrune = {
    enable = true;
    dates = "weekly";
  };

  # Enable SSH for remote management
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
    };
  };

  # Increase open file limits for k3s
  systemd.extraConfig = ''
    DefaultLimitNOFILE=1048576
  '';

  # Kernel parameters for k3s
  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    "net.bridge.bridge-nf-call-iptables" = 1;
    "net.bridge.bridge-nf-call-ip6tables" = 1;
  };

  # Load required kernel modules
  boot.kernelModules = [
    "br_netfilter"
    "overlay"
  ];
}
