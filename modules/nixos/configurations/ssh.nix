{
  values,
  ...
}:

{
  services.openssh = {
    enable = true;
    ports = [ 22 ];
    settings = {
      # Security hardening - disable password auth once keys are working
      PasswordAuthentication = true;
      PubkeyAuthentication = true;
      PermitRootLogin = "prohibit-password";
      X11Forwarding = false;
      PermitEmptyPasswords = false;
      ChallengeResponseAuthentication = false;
      UsePAM = true;
    };
    openFirewall = true;
  };

  # Authorized keys for the primary user
  users.users.${values.user.username}.openssh.authorizedKeys.keys = [
    # GitHub (Default) SSH Key - from 1Password
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGbqXvBhZI87E+Jj1i9L1MqQ71JRPofArCC0iRvZRIMV"
  ];

  # Also allow root login temporarily for recovery (uses same key)
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGbqXvBhZI87E+Jj1i9L1MqQ71JRPofArCC0iRvZRIMV"
  ];

  networking.firewall.allowedTCPPorts = [ 22 ];
}
