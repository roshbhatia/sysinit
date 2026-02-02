{
  config,
  lib,
  ...
}:

{
  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
    enableNushellIntegration = true;
  };

  home.sessionVariables = {
    _ZO_FZF_OPTS = builtins.concatStringsSep " " (
      [
        "--layout=reverse"
        "--height=80%"
        "--info=inline"
        "--scheme=history"
        "--bind=resize:refresh-preview"
        "--bind=ctrl-/:toggle-preview"
      ]
      ++ lib.optionals (config.stylix.enable or false) [
        "--color=bg:-1"
        "--color=bg+:-1"
        "--color=fg:#${config.lib.stylix.colors.base05}"
        "--color=fg+:#${config.lib.stylix.colors.base06}"
        "--color=gutter:-1"
        "--color=header:#${config.lib.stylix.colors.base0A}"
        "--color=hl:#${config.lib.stylix.colors.base0D}"
        "--color=hl+:#${config.lib.stylix.colors.base0D}"
        "--color=info:#${config.lib.stylix.colors.base0A}"
        "--color=marker:#${config.lib.stylix.colors.base0D}"
        "--color=pointer:#${config.lib.stylix.colors.base0D}"
        "--color=preview-bg:-1"
        "--color=prompt:#${config.lib.stylix.colors.base0D}"
        "--color=spinner:#${config.lib.stylix.colors.base0D}"
      ]
    );
  };
}
