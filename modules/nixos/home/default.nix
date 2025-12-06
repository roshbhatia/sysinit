{
  lib,
  values,
  ...
}:

{
  imports = [
    ./hyprland.nix
    ./waybar.nix
  ];

  home.stateVersion = "24.11";

  home.username = values.user.username;
  home.homeDirectory = lib.mkDefault "/home/${values.user.username}";
}
