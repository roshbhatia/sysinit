{
  values,
  ...
}:

{
  services.openssh = {
    enable = true;
    ports = [ 22 ];
    settings = {
      # Security hardening
      PasswordAuthentication = false;
      PubkeyAuthentication = true;
      PermitRootLogin = "prohibit-password";
      X11Forwarding = true;
      PermitEmptyPasswords = false;
      ChallengeResponseAuthentication = false;
      UsePAM = true;
    };
    openFirewall = true;
  };

  # Authorized keys for the primary user
  users.users.${values.user.username}.openssh.authorizedKeys.keys = [
    # Main SSH Key
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIWYK84u+ZlSasw3Z7LwsA2eT9S7xDXKVj61xOqAubKe rshnbhatia@lv426"
  ];

  # Also allow root login temporarily for recovery (uses same key)
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIWYK84u+ZlSasw3Z7LwsA2eT9S7xDXKVj61xOqAubKe rshnbhatia@lv426"
  ];

  networking.firewall.allowedTCPPorts = [ 22 ];

  # The OpenSSH agent remembers private keys for you
  # so that you don't have to type in passphrases every time you make an SSH connection.
  # Use `ssh-add` to add a key to the agent.
  # Disable on NixOS systems (conflict with GNOME SSH agent)
  programs.ssh.startAgent = false;
}
