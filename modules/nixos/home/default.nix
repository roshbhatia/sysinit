{
  lib,
  values,
  ...
}:

{
  imports = [
    ./mako.nix
    ./hyprland.nix
    ./waybar.nix
    ./wofi.nix
  ];

  home.stateVersion = lib.mkForce "24.11";

  home.username = values.user.username;
  home.homeDirectory = lib.mkDefault "/home/${values.user.username}";
}
