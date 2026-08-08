{ pkgs, ... }:

{
  programs.tmux = {
    enable = true;
    package = pkgs.tmux;
    mouse = true;

    extraConfig = ''
      set -g allow-passthrough on
    '';
  };
}
