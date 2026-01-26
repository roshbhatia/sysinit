{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
let
  shell = import ../shared/lib/shell.nix { inherit lib; };
  paths_lib = import ../shared/lib/paths.nix { inherit config lib; };

  sharedAliases = shell.aliases;
  pathsList = paths_lib.getAllPaths config.home.username config.home.homeDirectory;

  nushellBuiltins = [
    "find"
    "watch"
    "diff"
    "grep"
  ];
  aliases = removeAttrs sharedAliases nushellBuiltins;
in
{
  xdg.dataFile."nushell/custom-commands.nu" = {
    source = ./configurations/nushell/custom-commands.nu;
  };

  programs.nushell = {
    enable = true;
    package = pkgs.nushell.override {
      additionalFeatures = p: p ++ [ "mcp" ];
    };

    shellAliases = mkForce aliases;

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
        };
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
      CARAPACE_BRIDGES = "zsh,bash";
    };

    extraEnv = ''
      use std/util "path add"

      ${concatMapStringsSep "\n" (path: "path add \"${path}\"") pathsList}
    '';

    extraConfig = ''
      use std/dirs shells-aliases *

      # Load custom commands from vendor autoload directory
      source ${config.xdg.dataHome}/nushell/custom-commands.nu

      # Enhanced keybindings with FZF-style shortcuts
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
        {
          name: file_finder
          modifier: control
          keycode: char_t
          mode: [vi_insert vi_normal]
          event: {
            send: executehostcommand
            cmd: "vf"
          }
        }
        {
          name: dir_finder
          modifier: control
          keycode: char_g
          mode: [vi_insert vi_normal]
          event: {
            send: executehostcommand
            cmd: "cdf"
          }
        }
      ]

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

      # Enhanced zoxide with pushd support for directory stack management
      def --env --wrapped __zoxide_z_pushd [...rest: string] {
        if ('DIR_STACK' not-in $env) {
          $env.DIR_STACK = []
        }
        $env.DIR_STACK = ([$env.PWD] ++ $env.DIR_STACK)

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

      def --env --wrapped __zoxide_zi_pushd [...rest:string] {
        if ('DIR_STACK' not-in $env) {
          $env.DIR_STACK = []
        }
        $env.DIR_STACK = ([$env.PWD] ++ $env.DIR_STACK)
        cd $'(zoxide query --interactive -- ...$rest | str trim -r -c "\n")'
      }

      alias z = __zoxide_z_pushd
      alias zi = __zoxide_zi_pushd

      # Load secrets from ~/.nushell-secrets.nu (if exists)
      # Note: source requires literal path, using try to handle missing file gracefully
      try {
        source ~/.nushell-secrets.nu
      }

      # Performance monitoring in debug mode
      if ('SYSINIT_DEBUG' in $env) {
        print $"Nushell startup time: ($nu.startup-time)"
      }

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
      ${optionalString pkgs.stdenv.isDarwin ''
        alias nu-open = open
        alias open = ^open
      ''}

      oh-my-posh init nu --config ${config.xdg.configHome}/oh-my-posh/themes/sysinit.omp.json
    '';
  };

}
