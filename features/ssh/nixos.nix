{ values, ... }:

{
  services.openssh = {
    enable = true;
    startWhenNeeded = false;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
      X11Forwarding = false;

      SetEnv = "SHELL=/run/current-system/sw/bin/zsh PATH=/run/wrappers/bin:/etc/profiles/per-user/${values.user.username}/bin:/run/current-system/sw/bin:/nix/var/nix/profiles/default/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin";
    };
  };
}
