{
  config,
  lib,
  colors,
  appTheme,
}:
{
  # Core environment variables (POSIX compatible)
  LANG = "en_US.UTF-8";
  LC_ALL = "en_US.UTF-8";
  SUDO_EDITOR = "nvim";
  VISUAL = "nvim";
  EDITOR = "nvim";
  GIT_DISCOVERY_ACROSS_FILESYSTEM = "1";
  COLIMA_HOME = "\${config.xdg.configHome}/colima";
  ZK_NOTEBOOK_DIR = "$HOME/github/personal/roshbhatia/zeek/notes";

  # FZF colors (theme-aware)
  FZF_DEFAULT_OPTS = builtins.concatStringsSep " " [
    "--bind='resize:refresh-preview'"
    "--color=bg+:-1,bg:-1,spinner:${colors.accent.primary},hl:${colors.accent.primary}"
    "--color=border:${colors.background.overlay},label:${colors.foreground.primary}"
    "--color=fg:${colors.foreground.primary},header:${colors.accent.primary},info:${colors.foreground.muted},pointer:${colors.accent.primary}"
    "--color=marker:${colors.accent.primary},fg+:${colors.foreground.primary},prompt:${colors.accent.primary},hl+:${colors.accent.primary}"
    "--color=preview-bg:-1,query:${colors.foreground.primary}"
    "--cycle"
    "--height=30"
    "--highlight-line"
    "--ignore-case"
    "--info=inline"
    "--input-border=rounded"
    "--layout=reverse"
    "--list-border=rounded"
    "--no-scrollbar"
    "--pointer='>'"
    "--preview-border=rounded"
    "--prompt='>> '"
    "--scheme='history'"
    "--style='minimal'"
  ];

  FZF_DEFAULT_COMMAND = "fd --type f --hidden --follow --exclude .git --exclude node_modules";

  # Vivid theme
  VIVID_THEME = appTheme;
}
