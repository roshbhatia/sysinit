{
  pkgs,
  ...
}:

{
  # kubelet copies the node's search domains into every pod, and the node list
  # ends with fridas.club, which AdGuard answers with a wildcard pointing at the
  # Cilium Gateway. At the default ndots:5 a name with fewer than five dots tries
  # that list before itself, so api.anthropic.com resolves as
  # api.anthropic.com.fridas.club and every pod reaching the internet gets the
  # gateway. It surfaces as ECONNRESET, so it does not look like DNS.
  #
  # Pods read this file instead of /etc/resolv.conf, so they inherit the tailnet
  # domains and never the wildcard. The node keeps resolving *.fridas.club.
  #
  # 100.100.100.100 is Tailscale MagicDNS, which is the node's only resolver and
  # is a fixed address. CoreDNS runs with dnsPolicy Default, so this file is also
  # what it forwards to; changing the nameserver here changes cluster DNS egress.
  # The search domains come from `tailscale status --json | jq .MagicDNSSuffix`
  # and the second tailnet, and go stale if either changes.
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
