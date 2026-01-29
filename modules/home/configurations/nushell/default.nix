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
      CARAPACE_BRIDGES = "fish";
    };

    extraEnv = ''
      use std/util "path add"

      ${concatMapStringsSep "\n" (path: "path add \"${path}\"") pathsList}
    '';

    extraConfig = ''
      use std/dirs shells-aliases *

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

      export-env {
        $env.config = (
          $env.config?
          | default {}
          | upsert hooks { default {} }
          | upsert hooks.env_change { default {} }
          | upsert hooks.env_change.PWD { default [] }
        )
      }

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
