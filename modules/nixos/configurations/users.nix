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
    ];
    description = values.git.name;
  };

  security.sudo = {
    enable = true;
    wheelNeedsPassword = false;
  };
}
