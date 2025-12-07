{
  lib,
  username,
  ...
}:

{
  imports = [
    ./lib-hm-setup.nix
    # TODO: Fix home-manager lib.hm issue in NixOS integration
    # ./niri.nix
    # ./waybar.nix
  ];

  home.stateVersion = "24.11";

  home.username = username;
  home.homeDirectory = lib.mkDefault "/home/${username}";
}
