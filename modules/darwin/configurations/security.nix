{ values, ... }:

{
  # Touch ID for sudo
  security.pam.services.sudo_local.touchIdAuth = true;

  # Passwordless sudo for user
  security.sudo.extraConfig = ''
    ${values.user.username} ALL=(ALL) NOPASSWD: ALL
  '';
}
