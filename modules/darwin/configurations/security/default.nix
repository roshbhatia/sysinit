{
  values,
  ...
}:
{
  security.pam.services.sudo_local.touchIdAuth = true;

  security.sudo.extraRules = [
    {
      users = [ values.user.username ];
      commands = [
        {
          command = "ALL";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];
}
