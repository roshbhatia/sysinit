{ ... }:

{
  programs.tmux = {
    enable = true;
    mouse = true;

    extraConfig = ''
      set -g status off
      set -g allow-passthrough on
    '';
  };
}
