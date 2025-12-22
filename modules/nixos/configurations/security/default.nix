{
  values,
  ...
}:

{
  security.sudo = {
    enable = true;
    wheelNeedsPassword = false;
    extraConfig = ''
      # Reduce password prompt frequency
      Defaults lecture="never"
    '';
  };

  # SSH hardening - key-based auth, no passwords, no X11 forwarding
  services.openssh = {
    enable = true;
    ports = [ 22 ];
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
      X11Forwarding = false;
      PrintMotd = false;
      AllowUsers = [ values.user.username ];
    };
  };

  # SSH authorized keys from primary development machine
  users.users.${values.user.username}.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIWYK84u+ZlSasw3Z7LwsA2eT9S7xDXKVj61xOqAubKe rshnbhatia@lv426"
  ];
}
