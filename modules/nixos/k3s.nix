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
    ];
  };

  hardware.nvidia-container-toolkit.enable = true;

  environment.systemPackages = with pkgs; [
    kubectl
    k3s
  ];

  networking.firewall.allowedTCPPorts = [ 6443 ];
}
