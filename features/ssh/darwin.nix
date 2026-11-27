{
  config,
  lib,
  ...
}:

let
  cfg = config.sysinit.darwin.openssh;
  inherit (config.sysinit.user) username;
in
{
  config = lib.mkIf cfg.enable {
    services.openssh = {

      enable = true;

      extraConfig = ''
        PasswordAuthentication no
        KbdInteractiveAuthentication no
        PermitRootLogin no
      '';
    };

    users.users.${username}.openssh.authorizedKeys.keys = cfg.authorizedKeys;
  };
}
