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
  toolAliases = builtins.removeAttrs sharedAliases.tools nushellBuiltins;
  nuShortcuts = lib.mapAttrs (
    _: value: lib.replaceStrings [ "$HOME" ] [ "~" ] value
  ) sharedAliases.shortcuts;
in
{
  programs.nushell = {
    enable = true;
    package = pkgs.nushell.override {
      additionalFeatures = p: p ++ [ "mcp" ];
    };

    shellAliases = lib.mkForce (
      toolAliases // sharedAliases.listing // sharedAliases.navigation // nuShortcuts
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
        vi_insert = "line";
        vi_normal = "block";
      };
      history = {
        max_size = 50000;
        sync_on_enter = true;
        file_format = "sqlite";
        isolation = false;
      };
    };

    environmentVariables = {
      LANG = "en_US.UTF-8";
      LC_ALL = "en_US.UTF-8";
      VISUAL = "nvim";
      EDITOR = "nvim";
      SUDO_EDITOR = "nvim";
      GIT_DISCOVERY_ACROSS_FILESYSTEM = "1";
      FZF_DEFAULT_COMMAND = "fd --type f --hidden --follow --exclude .git --exclude node_modules";
      VIVID_THEME = appTheme;
      CARAPACE_BRIDGES = "zsh,fish,bash";
    };

    extraEnv = ''
      use std/util "path add"

      $env.XDG_CACHE_HOME = "${config.xdg.cacheHome}"
      $env.XDG_CONFIG_HOME = "${config.xdg.configHome}"
      $env.XDG_DATA_HOME = "${config.xdg.dataHome}"
      $env.XDG_STATE_HOME = "${config.xdg.stateHome}"
      $env.XCA = "${config.xdg.cacheHome}"
      $env.XCO = "${config.xdg.configHome}"
      $env.XDA = "${config.xdg.dataHome}"
      $env.XST = "${config.xdg.stateHome}"

      ${lib.concatMapStringsSep "\n" (path: "path add \"${path}\"") pathsList}

      mkdir $"($nu.cache-dir)"
      carapace _carapace nushell | save --force $"($nu.cache-dir)/carapace.nu"
    '';

    extraConfig = ''
      use std/dirs shells-aliases *

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

      # Zoxide integration
      export-env {
        $env.config = (
          $env.config?
          | default {}
          | upsert hooks { default {} }
          | upsert hooks.env_change { default {} }
          | upsert hooks.env_change.PWD { default [] }
        )
        let __zoxide_hooked = (
          $env.config.hooks.env_change.PWD | any { try { get __zoxide_hook } catch { false } }
        )
        if not $__zoxide_hooked {
          $env.config.hooks.env_change.PWD = ($env.config.hooks.env_change.PWD | append {
            __zoxide_hook: true,
            code: {|_, dir| zoxide add -- $dir}
          })
        }
      }

      def --env --wrapped __zoxide_z [...rest: string] {
        let path = match $rest {
          [] => {'~'},
          [ '-' ] => {'-'},
          [ $arg ] if ($arg | path expand | path type) == 'dir' => {$arg}
          _ => {
            zoxide query --exclude $env.PWD -- ...$rest | str trim -r -c "\n"
          }
        }
        cd $path
      }

      def --env --wrapped __zoxide_zi [...rest:string] {
        cd $'(zoxide query --interactive -- ...$rest | str trim -r -c "\n")'
      }

      alias z = __zoxide_z
      alias zi = __zoxide_zi

      # Kubernetes
      alias kubectl = kubecolor

      # WezTerm integration
      if (which wezterm | is-not-empty) {
        $env.config.hooks.env_change.PWD = (
          $env.config.hooks.env_change.PWD?
          | default []
          | append { ||
              try { wezterm set-working-directory } catch { }
            }
        )
      }

      # macOS: preserve system open command
      ${lib.optionalString pkgs.stdenv.isDarwin ''
        alias nu-open = open
        alias open = ^open
      ''}

      source $"($nu.cache-dir)/carapace.nu"

      oh-my-posh init nu --config ${config.xdg.configHome}/oh-my-posh/themes/sysinit.omp.json
    '';
  };

}
