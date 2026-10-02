{
  pkgs,
  ...
}:

{

  environment.etc."k3s/resolv.conf".text = ''
    search stork-eel.ts.net taila415c.ts.net
    nameserver 100.100.100.100
    options edns0
  '';

  services.k3s = {
    enable = true;
    role = "server";
    extraFlags = builtins.concatStringsSep " " [
      "--write-kubeconfig-mode=0644"
      "--tls-san=arrakis"
      "--nonroot-devices"
      "--resolv-conf=/etc/k3s/resolv.conf"
    ];
  };

  hardware.nvidia-container-toolkit.enable = true;

  environment.systemPackages = with pkgs; [
    kubectl
    k3s
  ];

  networking.firewall.allowedTCPPorts = [ 6443 ];
}
