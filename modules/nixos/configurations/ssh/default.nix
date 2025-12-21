{ values, ... }:

{
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = true;
      PermitRootLogin = "no";
      X11Forwarding = false;
    };
  };

  users.users.${values.user.username}.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIWYK84u+ZlSasw3Z7LwsA2eT9S7xDXKVj61xOqAubKe rshnbhatia@lv426"
  ];
}
