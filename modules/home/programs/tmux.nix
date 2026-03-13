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

  # Stylix handles tmux colors by default when programs.tmux.enable is true
  stylix.targets.tmux.enable = true;
}
