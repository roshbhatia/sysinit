{
  lib,
  username,
  ...
}:

{
  imports = [
    ./niri.nix
    ./waybar.nix
  ];

  home.stateVersion = "24.11";

  home.username = username;
  home.homeDirectory = lib.mkDefault "/home/${username}";
}
