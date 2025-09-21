{
  values,
  ...
}:
{
  security.pam.services.sudo_local.touchIdAuth = true;

  security.sudo.extraConfig = ''
    ${values.user.username} ALL=(ALL) NOPASSWD: ALL
  '';
}
