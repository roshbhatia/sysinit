{ config, pkgs, lib, ... }: {
  imports = [
    ./git.nix
    ./starship.nix
    ./zsh.nix
    ./atuin.nix
    ./k9s.nix
    ./macchina.nix
    ./nvim.nix
    ./wezterm.nix
  ];
}
