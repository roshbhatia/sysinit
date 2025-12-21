{
  values,
  pkgs,
  lib,
  config,
  ...
}:

{
  users.users.${values.user.username} = {
    isNormalUser = true;
    createHome = true;
    home = "/home/${values.user.username}";
    group = values.user.username;
    shell = pkgs.zsh;
    extraGroups = [
      "wheel"
      "networkmanager"
      "video"
      "audio"
      "input"
    ]
    ++ lib.optionals config.programs.gamemode.enable [ "gamemode" ];
    description = values.git.name;
  };

  users.groups.${values.user.username} = { };
}
