{ pkgs, ... }:

{
  programs.tmux = {
    enable = true;
    package = pkgs.tmux;
    mouse = true;

    extraConfig = ''
      # Enable OSC 1337 user vars passthrough for WezTerm integration
      set -g allow-passthrough on
    '';
  };
}
