{
  lib,
  values,
  ...
}:

{
  imports = [
    ./configurations/mako
    ./configurations/hyprland
    ./configurations/waybar
    ./configurations/wofi
  ];

  home.stateVersion = lib.mkForce "24.11";

  home.username = values.user.username;
  home.homeDirectory = lib.mkDefault "/home/${values.user.username}";
}
