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

    plugins = with pkgs.tmuxPlugins; [
      {
        plugin = resurrect;
        extraConfig = ''
          set -g @resurrect-strategy-nvim 'session'
        '';
      }
      {
        plugin = continuum;
        extraConfig = ''
          set -g @continuum-restore 'on'
          set -g @continuum-save-interval '10'
        '';
      }
    ];
  };

  # Stylix handles tmux colors by default when programs.tmux.enable is true,
  # but we can be explicit if needed.
  stylix.targets.tmux.enable = true;
}
