{ config, ... }:

{
  security.pam.services.sudo_local.touchIdAuth = true;

  security.sudo.extraConfig = ''
    ${config.sysinit.user.username} ALL=(ALL) NOPASSWD: ALL
  '';
}
