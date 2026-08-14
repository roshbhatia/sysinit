{
  config,
  lib,
  ...
}:
let
  themeLib = import ../../shared/theme-colors.nix { inherit lib; };
  themeColors = themeLib.colorsOf config;
  themeEnabled = themeLib.enabled config;
in

{
  programs.zoxide = {
    enable = true;

    enableNushellIntegration = true;
    enableZshIntegration = true;
  };

  home.sessionVariables = {
    _ZO_FZF_OPTS = builtins.concatStringsSep " " (
      [
        "--bind=ctrl-d:half-page-down"
        "--bind=ctrl-f:jump,jump:accept"
        "--bind=ctrl-k:toggle-preview"
        "--bind=ctrl-u:half-page-up"
        "--bind=resize:refresh-preview"
        "--bind=shift-tab:up"
        "--bind=tab:down"
        "--border=none"
        "--gutter=' '"
        "--height=80%"
        "--info=inline"
        "--jump-labels=fjdkslaghrueiwoncmv"
        "--layout=reverse"
        "--scheme=history"
        "--style=minimal"
      ]
      ++ lib.optionals themeEnabled [
        "--color=bg:-1"
        "--color=bg+:-1"
        "--color=fg:#${themeColors.base05}"
        "--color=fg+:#${themeColors.base06}"
        "--color=gutter:-1"
        "--color=header:#${themeColors.base0A}"
        "--color=hl:#${themeColors.base0D}"
        "--color=hl+:#${themeColors.base0D}"
        "--color=info:#${themeColors.base0A}"
        "--color=marker:#${themeColors.base0D}"
        "--color=pointer:#${themeColors.base0D}"
        "--color=preview-bg:-1"
        "--color=prompt:#${themeColors.base0D}"
        "--color=spinner:#${themeColors.base0D}"
      ]
    );
  };
}
