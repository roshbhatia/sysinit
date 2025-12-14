{
  lib,
  values,
  ...
}:

{
  imports = [
    ./foot.nix
    ./mako.nix
    ./niri.nix
    ./waybar.nix
    ./wofi.nix
  ];

  home.stateVersion = lib.mkForce "24.11";

  home.username = values.user.username;
  home.homeDirectory = lib.mkDefault "/home/${values.user.username}";
}
