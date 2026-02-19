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
    shellAliases = mkDefault aliases;

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
    '';

    extraConfig = ''
      use std/dirs shells-aliases *

      # External completer using fish for better completion support
      let fish_completer = {|spans|
        fish --command $"complete '--do-complete=($spans | str replace --all "'" "\\'" | str join ' ')'"
        | from tsv --flexible --noheaders --no-infer
        | rename value description
        | update value {|row|
          let value = $row.value
          let need_quote = ['\' ',' '[' ']' '(' ')' ' ' '\t' "'" '"' "`"] | any {$in in $value}
          if ($need_quote and ($value | path exists)) {
            let expanded_path = if ($value starts-with ~) {$value | path expand --no-symlink} else {$value}
            $'"($expanded_path | str replace --all "\"" "\\\"")"'
          } else {$value}
        }
      }

      $env.config.completions.external = {
        enable: true
        completer: $fish_completer
      }

      # macOS: preserve system open command
      ${optionalString pkgs.stdenv.isDarwin ''
        alias nu-open = open
        alias open = ^open
      ''}
    '';
  };
}
