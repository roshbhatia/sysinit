{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
let
  shell = import ../../lib/shell.nix { inherit lib; };
  paths_lib = import ../../lib/paths.nix { inherit config lib; };

  pathsList = paths_lib.getAllPaths config.home.username config.home.homeDirectory;
  carapaceBin = "${pkgs.carapace}/bin/carapace";
in
{
  programs.nushell = {
    enable = true;
    shellAliases = mkDefault shell.commonAliases;

    settings = {
      show_banner = false;
      edit_mode = "vi";
      cursor_shape = {
        vi_insert = "line";
        vi_normal = "block";
      };
      keybindings = [
        {
          name = "completion_menu";
          modifier = "none";
          keycode = "tab";
          mode = [
            "emacs"
            "vi_normal"
            "vi_insert"
          ];
          event = {
            until = [
              {
                send = "menu";
                name = "completion_menu";
              }
              { send = "menunext"; }
              { edit = "complete"; }
            ];
          };
        }
      ];
      hooks = {
        env_change = {
          PWD = lib.hm.nushell.mkNushellInline ''
            [
              {||
                if (which wezterm | is-not-empty) {
                  try { wezterm set-working-directory } catch { }
                }
              }
            ]
          '';
        };
      };
    };

    extraEnv = ''
      use std/util "path add"

      ${concatMapStringsSep "\n" (path: "path add \"${path}\"") pathsList}

      $env.CARAPACE_LENIENT = "1"
    '';

    extraConfig = ''
      use std/dirs shells-aliases *

      let carapace_completer = {|spans: list<string>|
        if $spans.0 == "nu" { return null }

        let spans = if $spans.0 in ["k", "kubecolor"] {
          $spans | skip 1 | prepend "kubectl"
        } else {
          $spans
        }

        let result = (
          do { timeout 3sec ${carapaceBin} $spans.0 nushell ...$spans }
          | complete
        )

        if $result.exit_code != 0 { return null }

        try { $result.stdout | from json } catch { null }
      }

      $env.config.completions.external.enable = true
      $env.config.completions.external.max_results = 100
      $env.config.completions.external.completer = $carapace_completer

      # macOS: preserve system open command
      ${optionalString pkgs.stdenv.isDarwin ''
        alias nu-open = open
        alias open = ^open
      ''}
    '';
  };
}
