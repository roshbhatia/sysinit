{
  config,
  lib,
  values,
  pkgs,
  ...
}:

let
  shell = import ../../../shared/lib/shell { inherit lib; };
  themes = import ../../../shared/lib/theme { inherit lib; };
  paths_lib = import ../../../shared/lib/paths { inherit config lib; };

  validatedTheme = values.theme;
  appTheme = themes.getAppTheme "vivid" validatedTheme.colorscheme validatedTheme.variant;
  sharedAliases = shell.aliases;
  pathsList = paths_lib.getAllPaths config.home.username config.home.homeDirectory;

  nushellBuiltins = [
    "find"
    "watch"
    "diff"
    "grep"
  ];
  toolAliases = builtins.removeAttrs sharedAliases.tools nushellBuiltins // {
    cat = "bat -pp";
  };
  listingAliases = builtins.removeAttrs sharedAliases.listing [ "ls" ];
  kubernetesAliases = sharedAliases.kubernetes;

  promptConfig = builtins.readFile ./ui/prompt.nu;
  keybindingsConfig = builtins.readFile ./ui/keybindings.nu;
  wezTermConfig = builtins.readFile ./integrations/wezterm.nu;
  functionsConfig = builtins.readFile ./core/functions.nu;
in
{
  stylix.targets.nushell.enable = true;

  programs.nushell = {
    enable = true;
    package = pkgs.nushell.override {
      additionalFeatures = p: p ++ [ "mcp" ];
    };

    shellAliases = lib.mkForce (
      toolAliases
      // listingAliases
      // kubernetesAliases
      // {
        sg = "ast-grep";
      }
    );

    settings = {
      show_banner = false;
      edit_mode = "vi";
      completions = {
        case_sensitive = false;
        quick = true;
        partial = true;
        algorithm = "fuzzy";
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

    extraEnv = ''
      use std/util "path add"

      # Core environment
      $env.LANG = "en_US.UTF-8"
      $env.LC_ALL = "en_US.UTF-8"
      $env.EDITOR = "nvim"
      $env.VISUAL = "nvim"
      $env.SUDO_EDITOR = "nvim"

      # XDG Base Directory - critical for scripts to find configs
      $env.HOME = "${config.home.homeDirectory}"
      $env.XDG_CACHE_HOME = "${config.xdg.cacheHome}"
      $env.XDG_CONFIG_HOME = "${config.xdg.configHome}"
      $env.XDG_DATA_HOME = "${config.xdg.dataHome}"
      $env.XDG_STATE_HOME = "${config.xdg.stateHome}"
      $env.XCA = "${config.xdg.cacheHome}"
      $env.XCO = "${config.xdg.configHome}"
      $env.XDA = "${config.xdg.dataHome}"
      $env.XST = "${config.xdg.stateHome}"

      # Application-specific
      $env.GIT_DISCOVERY_ACROSS_FILESYSTEM = "1"
      $env.COLIMA_HOME = "${config.xdg.configHome}/colima"
      $env.FZF_DEFAULT_COMMAND = "fd --type f --hidden --follow --exclude .git --exclude node_modules"
      $env.VIVID_THEME = "${appTheme}"
      $env.ZK_NOTEBOOK_DIR = "${config.home.homeDirectory}/github/personal/roshbhatia/zeek/notes"

      # PATH configuration
      ${lib.concatMapStringsSep "\n" (path: "path add \"${path}\"") pathsList}

      # Navigation commands - these need to be def --env, not aliases
      ${lib.concatStringsSep "\n" (
        lib.mapAttrsToList (
          name: value:
          let
            nuValue = lib.replaceStrings [ "$HOME" ] [ "$env.HOME" ] value;
          in
          "def --env ${name} [] { ${nuValue} }"
        ) (sharedAliases.navigation // sharedAliases.shortcuts)
      )}
    '';

    extraConfig = ''
      ${promptConfig}
      ${keybindingsConfig}
      ${wezTermConfig}
      ${functionsConfig}

      # Cobra completion support (for kubectl, gh, etc.)
      if ("~/.config/nushell/ext/cobra-completer.nu" | path expand | path exists) {
        source ~/.config/nushell/ext/cobra-completer.nu
      }

      # Zoxide completions
      let zoxide_completer = {|spans|
        $spans | skip 1 | zoxide query -l ...$in | lines | where {|x| $x != $env.PWD}
      }

      # Carapace completions
      let carapace_completer = {|spans|
        let expanded_alias = (scope aliases | where name == $spans.0 | get -o 0 | get -o expansion)
        let spans = (if $expanded_alias != null {
          $spans | skip 1 | prepend ($expanded_alias | split row " " | take 1)
        } else {
          $spans
        })
        carapace $spans.0 nushell ...$spans | from json
      }

      # External completer with fallback chain
      let external_completer = {|spans|
        let expanded_alias = scope aliases | where name == $spans.0 | get -o 0.expansion
        let spans = if $expanded_alias != null {
          $spans | skip 1 | prepend ($expanded_alias | split row ' ' | take 1)
        } else {
          $spans
        }

        match $spans.0 {
          __zoxide_z | __zoxide_zi => $zoxide_completer
          make => null
          _ => $carapace_completer
        } | do $in $spans
      }

      $env.config.completions = {
        external: {
          enable: true
          completer: $external_completer
        }
      }

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
      const omp_cache = "~/.cache/omp.nu"
      if (which oh-my-posh | is-not-empty) {
        if not ($omp_cache | path expand | path exists) {
          try {
            oh-my-posh init nu --config ~/.config/oh-my-posh/themes/sysinit.omp.json | save --force ($omp_cache | path expand)
          } catch { }
        }
      }
      if ($omp_cache | path expand | path exists) {
        source ~/.cache/omp.nu
      }

      # Load custom utilities
      if ("~/.config/nushell/ext/k8s-utils.nu" | path expand | path exists) {
        use ~/.config/nushell/ext/k8s-utils.nu *
      }

      # Use shells-aliases from std/dirs (cd history navigation)
      use std/dirs shells-aliases *
    '';
  };

  # External configuration files
  xdg.configFile."nushell/ext" = {
    source = ./ext;
  };
}
