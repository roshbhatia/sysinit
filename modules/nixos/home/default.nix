{
  lib,
  values,
  ...
}:

{
  imports = [
    ./configurations/mako
    ./configurations/waybar
    ./configurations/wofi
    ./configurations/nixpkgs
    ./configurations/quickshell
    ./configurations/wallpapers
    ./configurations/wezterm-retroism
    ./configurations/gtk-retroism
    ./configurations/nemo
  ];

  home.stateVersion = lib.mkForce "24.11";

  home.username = values.user.username;
  home.homeDirectory = lib.mkDefault "/home/${values.user.username}";
}
