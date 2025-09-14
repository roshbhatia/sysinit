{
  config,
  values,
  utils,
  pkgs,
  ...
}:

let
  inherit (utils.themes) mkThemedConfig;
  themeCfg = mkThemedConfig values "nushell" { };
  inherit (themeCfg) themes;
  nushellTheme = themeCfg.appTheme;
  palette = themes.getThemePalette values.theme.colorscheme values.theme.variant;
  colors = themes.getUnifiedColors palette;

in
{
  programs.nushell = {
    enable = true;

    configFile.source = ./system/config.nu;
    envFile.source = ./system/env.nu;

    extraEnv = ''
      $env.FZF_DEFAULT_OPTS = "${
        builtins.concatStringsSep " " [
          "--bind=resize:refresh-preview"
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
          "--scheme=history"
          "--style=minimal"
        ]
      }"
    '';

    shellAliases = {
      "....." = "cd ../../../..";
      "...." = "cd ../../..";
      "..." = "cd ../..";
      ".." = "cd ..";
      "~" = "cd ~";

      c = "code-insiders";
      code = "code-insiders";
      h = "hx";
      v = "nvim";
      vd = "nvim -d";
      vimdiff = "nvim -d";

      cs = "claude-squad";

      kubectl = "kubecolor";
      tf = "terraform";
      y = "yazi";

      cat = "bat -pp";
      diff = "diff --color";
      grep = "grep -s --color=auto";
      sudo = "sudo -E";
      watch = "watch --quiet";

      nu-open = "open";
      open = "^open";
    };

    environmentVariables = config.home.sessionVariables;
  };

  xdg.configFile = {
    "nushell/autoload/${nushellTheme}".source = ./themes/${nushellTheme};
    "nushell/autoload/atuin.nu".source = ./integrations/atuin.nu;
    "nushell/autoload/completions.nu".source = ./integrations/completions.nu;
    "nushell/autoload/direnv.nu".source = ./integrations/direnv.nu;
    "nushell/autoload/zoxide.nu".source = ./integrations/zoxide.nu;

    "nushell/autoload/kubectl.nu".source = ./tools/kubectl.nu;

    "nushell/autoload/macchina.nu".source = ./ui/macchina.nu;
    "nushell/autoload/omp.nu".source = ./ui/omp.nu;

    "nushell/autoload/nix-your-shell.nu".source = pkgs.nix-your-shell.generate-config "nu";
    "nushell/autoload/wezterm.nu".source = ./ui/wezterm.nu;
  };
}
