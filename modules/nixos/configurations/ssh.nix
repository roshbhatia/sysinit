{
  services.openssh = {
    enable = true;
    ports = [ 22 ];
    settings = {
      PasswordAuthentication = false;
      PubkeyAuthentication = true;
      PermitRootLogin = "no";
    };
  };

  # Allow SSH through firewall if enabled
  networking.firewall.allowedTCPPorts = [ 22 ];
}
