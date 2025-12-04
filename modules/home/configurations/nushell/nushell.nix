{
  config,
  lib,
  values,
  ...
}:
let
  shell = import ../../../lib/shell { inherit lib; };
  themes = import ../../../lib/theme { inherit lib; };
  paths_lib = import ../../../lib/paths { inherit config lib; };

  validatedTheme = themes.validateThemeConfig values.theme;
  palette = themes.getThemePalette validatedTheme.colorscheme validatedTheme.variant;
  colors = themes.getUnifiedColors palette;

  appTheme = themes.getAppTheme "vivid" validatedTheme.colorscheme validatedTheme.variant;
  sharedAliases = shell.aliases;

  # Get all paths for PATH variable
  pathsList = paths_lib.getAllPaths config.home.username config.home.homeDirectory;

  # FZF options as a single string
  fzfOpts = builtins.concatStringsSep " " [
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
in
{
  programs.nushell = {
    enable = true;

    # Aliases - use mkForce to override home.shellAliases conflicts
    shellAliases = lib.mkForce (lib.foldl' (acc: aliases: acc // aliases) { } (
      lib.flatten [
        sharedAliases.navigation
        (builtins.removeAttrs sharedAliases.listing [ "ls" ])
        (sharedAliases.tools // { cat = "bat -pp"; })
      ]
    ));

    # Environment variables - properly typed for nushell
    environmentVariables = {
      LANG = "en_US.UTF-8";
      LC_ALL = "en_US.UTF-8";
      SUDO_EDITOR = "nvim";
      VISUAL = "nvim";
      EDITOR = "nvim";
      GIT_DISCOVERY_ACROSS_FILESYSTEM = "1";
      COLIMA_HOME = "${config.xdg.configHome}/colima";
      FZF_DEFAULT_COMMAND = "fd --type f --hidden --follow --exclude .git --exclude node_modules";
      FZF_DEFAULT_OPTS = fzfOpts;
      VIVID_THEME = appTheme;
      ZK_NOTEBOOK_DIR = "${config.home.homeDirectory}/github/personal/roshbhatia/zeek/notes";
    };

    settings = {
      show_banner = false;
      edit_mode = "vi";
      completions = {
        case_sensitive = false;
        quick = true;
        partial = true;
        algorithm = "fuzzy";
        external = {
          enable = true;
          max_results = 100;
        };
      };
      cursor_shape = {
        vi_insert = "underscore";
        vi_normal = "block";
      };
      history = {
        max_size = 50000;
        sync_on_enter = true;
        file_format = "sqlite";
        isolation = false;
      };
    };

    extraConfig = ''
      # Keybindings
      $env.config.keybindings = [
        {
          name: completion_menu
          modifier: none
          keycode: tab
          mode: [emacs vi_normal vi_insert]
          event: {
            until: [
              { send: menu name: completion_menu }
              { send: menunext }
              { edit: complete }
            ]
          }
        }
      ]

      # Wezterm shell integration - update working directory on PWD changes
      if (which wezterm | is-not-empty) {
        $env.config.hooks.env_change.PWD = (
          $env.config.hooks.env_change.PWD?
          | default []
          | append { ||
              try { wezterm set-working-directory } catch { }
            }
        )
      }

      # Macchina greeting (only in interactive terminal, not in nvim or wezterm pane)
      if ($env.WEZTERM_PANE? | is-empty) and ($env.NVIM? | is-empty) {
        if (which macchina | is-not-empty) {
          let macchina_theme = ($env.MACCHINA_THEME? | default "rosh")
          macchina --theme $macchina_theme
        }
      }

      # oh-my-posh initialization (if available)
      # Note: We use a fixed path since `source` requires parse-time constants
      const omp_cache = "~/.cache/omp.nu"
      if (which oh-my-posh | is-not-empty) {
        # Generate the init script if it doesn't exist
        if not ($omp_cache | path expand | path exists) {
          try {
            oh-my-posh init nu --config ~/.config/oh-my-posh/themes/sysinit.omp.json | save --force ($omp_cache | path expand)
          } catch { }
        }
      }
      # Source the cached script if it exists
      if ($omp_cache | path expand | path exists) {
        source ~/.cache/omp.nu
      }
    '';

    # Environment file - PATH setup and shortcuts
    envFile.text = ''
      # PATH configuration
      # Add paths that exist to the PATH
      def --env path-add-safe [dir: string] {
        if ($dir | path exists) {
          $env.PATH = ($env.PATH | split row (char esep) | prepend $dir | uniq)
        }
      }

      # Add all configured paths
      ${lib.concatMapStringsSep "\n" (path: "path-add-safe \"${path}\"") pathsList}

      # Directory shortcuts - define as functions
      ${lib.concatStringsSep "\n" (
        lib.mapAttrsToList (name: value: 
          let
            # Replace $HOME with $env.HOME for nushell compatibility
            nuValue = lib.replaceStrings ["$HOME"] ["$env.HOME"] value;
          in
          "def --env ${name} [] { ${nuValue} }"
        ) sharedAliases.shortcuts
      )}
    '';
  };
}
