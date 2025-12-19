{ values, ... }:

{
  users.mutableUsers = true;

  users.users."${values.user.username}" = {
    home = "/home/${values.user.username}";
    isNormalUser = true;
    createHome = true;
    initialPassword = "password";
    extraGroups = [
      "wheel"
      "networkmanager"
      "keyd"
    ];
    description = values.git.name;
  };

  users.groups.keyd = { };

  security.sudo = {
    enable = true;
    wheelNeedsPassword = false;
  };
}
