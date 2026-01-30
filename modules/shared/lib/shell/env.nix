{
  colors,
  lib,
  appTheme,
}:
let
  commonFzfOpts = [
    "--style=minimal"
    "--layout=reverse"
    "--height=80%"
    "--info=inline"
    "--scheme=history"
    "--bind=resize:refresh-preview"
    "--bind=ctrl-/:toggle-preview"
    "--color=bg+:-1,bg:-1,spinner:${colors.accent.primary},hl:${colors.accent.primary}"
    "--color=fg:${colors.foreground.primary},fg+:${colors.foreground.primary}"
    "--color=border:${colors.background.overlay},header:${colors.accent.primary}"
    "--color=info:${colors.foreground.muted},marker:${colors.accent.primary}"
    "--color=pointer:${colors.accent.primary},prompt:${colors.accent.primary}"
    "--color=preview-bg:-1"
  ];
in
{
  LANG = "en_US.UTF-8";
  LC_ALL = "en_US.UTF-8";
  SUDO_EDITOR = "nvim";
  VISUAL = "nvim";
  EDITOR = "nvim";
  GIT_DISCOVERY_ACROSS_FILESYSTEM = "1";

  FZF_DEFAULT_OPTS = lib.mkForce (builtins.concatStringsSep " " commonFzfOpts);

  _ZO_FZF_OPTS = builtins.concatStringsSep " " commonFzfOpts;

  FZF_DEFAULT_COMMAND = "fd --type f --hidden --follow --exclude .git --exclude node_modules";
}
