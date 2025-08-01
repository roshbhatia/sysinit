{
  config,
  lib,
  values,
  ...
}:

let
  themes = import ../../../lib/themes { inherit lib; };
  paths = import ../../../lib/paths { inherit config lib; };
  vividTheme = themes.getAppTheme "vivid" values.theme.colorscheme values.theme.variant;
  nushellTheme = themes.getAppTheme "nushell" values.theme.colorscheme values.theme.variant;
  palette = themes.getThemePalette values.theme.colorscheme values.theme.variant;
  colors = themes.getUnifiedColors palette;

  pathsList = paths.getAllPaths config.home.username config.home.homeDirectory;

in
{
  programs.nushell = {
    enable = true;

    configFile.source = ./system/config.nu;
    envFile.source = ./system/env.nu;

    extraConfig = ''
      # Environment setup
      $env.LS_COLORS = (vivid generate ${vividTheme})
      $env.EZA_COLORS = $env.LS_COLORS
    '';

    extraEnv = ''
      # Dynamic path configuration
      let paths = [
        ${lib.concatStringsSep "\n        " (map (path: "\"${path}\"") pathsList)}
        "${config.home.homeDirectory}/.config/carapace/bin"
      ]

      for path in $paths {
        path_add $path
      }

      # FZF theme configuration
      $env.FZF_DEFAULT_OPTS = [
        "--bind=resize:refresh-preview"
        "--color=bg+:-1,bg:-1,spinner:${colors.primary},hl:${colors.primary}"
        "--color=border:${colors.border},label:${colors.foreground}"
        "--color=fg:${colors.foreground},header:${colors.primary},info:${colors.muted},pointer:${colors.primary}"
        "--color=marker:${colors.primary},fg+:${colors.foreground},prompt:${colors.primary},hl+:${colors.primary}"
        "--color=preview-bg:-1,query:${colors.foreground}"
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
      ] | str join " "
    '';

    shellAliases = {
      # Navigation shortcuts
      "....." = "cd ../../../..";
      "...." = "cd ../../..";
      "..." = "cd ../..";
      ".." = "cd ..";
      "~" = "cd ~";

      # Editor shortcuts
      code = "code-insiders";
      c = "code-insiders";
      v = "nvim";

      # Tool shortcuts
      kubectl = "kubecolor";
      tf = "terraform";
      g = "git";
      y = "yazi";

      # Enhanced ls
      l = "ls";
      la = "ls -a";
      ll = "ls -la";
      lt = "eza --icons=always -1 -a -T --git-ignore --ignore-glob='.git'";

      # System utilities
      sudo = "sudo -E";
      diff = "diff --color";
      grep = "grep -s --color=auto";
      watch = "watch --quiet";

      # macOS compatibility
      nu-open = "open";
      open = "^open";
    };

    environmentVariables = config.home.sessionVariables;
  };

  xdg.configFile = {
    "nushell/autoload/${nushellTheme}".source = ./themes/${nushellTheme};

    # Integrations
    "nushell/autoload/atuin.nu".source = ./integrations/atuin.nu;
    "nushell/autoload/completions.nu".source = ./integrations/completions.nu;
    "nushell/autoload/direnv.nu".source = ./integrations/direnv.nu;
    "nushell/autoload/zoxide.nu".source = ./integrations/zoxide.nu;

    # Tools
    "nushell/autoload/kubectl.nu".source = ./tools/kubectl.nu;

    # UI
    "nushell/autoload/macchina.nu".source = ./ui/macchina.nu;
    "nushell/autoload/omp.nu".source = ./ui/omp.nu;
    "nushell/autoload/wezterm.nu".source = ./ui/wezterm.nu;
  };
}

