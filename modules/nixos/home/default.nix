{
  lib,
  values,
  ...
}:

{
  imports = [
    ./configurations/hyprland
    ./configurations/waybar
  ];

  home.stateVersion = "24.11";

  # Ensure home directory is set
  home.username = values.user.username;
  home.homeDirectory = lib.mkDefault "/home/${values.user.username}";
}
