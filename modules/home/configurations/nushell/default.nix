{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
let
  shell = import ../../../shared/lib/shell { inherit lib; };
  paths_lib = import ../../../shared/lib/paths { inherit config lib; };

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
      CARAPACE_BRIDGES = "zsh,fish,bash";
    };

    extraEnv = ''
      use std/util "path add"

      ${concatMapStringsSep "\n" (path: "path add \"${path}\"") pathsList}
    '';

    extraConfig = ''
      use std/dirs shells-aliases *

      # External completers (fish + carapace with fallback logic)
      let fish_completer = {|spans|
        fish --command $"complete '--do-complete=($spans | str replace --all "'" "\\'" | str join ' ')'"
        | from tsv --flexible --noheaders --no-infer
        | rename value description
        | update value {|row|
          let value = $row.value
          let need_quote = ['\' ',' '[' ']' '(' ')' ' ' '\t' "'" '"' "`"] | any {$in in $value}
          if ($need_quote and ($value | path exists)) {
            let expanded_path = if ($value | str starts-with ~) {$value | path expand --no-symlink} else {$value}
            $'"($expanded_path | str replace --all "\"" "\\\"")"'
          } else {$value}
        }
      }

      let carapace_completer = {|spans: list<string>|
        carapace $spans.0 nushell ...$spans
        | from json
        | if ($in | default [] | any {|| $in.display | str starts-with "ERR"}) { null } else { $in }
      }

      $env.config.completions.external.completer = {|spans|
        let expanded_alias = scope aliases
        | where name == $spans.0
        | get -o 0.expansion

        let spans = if $expanded_alias != null {
          $spans
          | skip 1
          | prepend ($expanded_alias | split row ' ' | take 1)
        } else {
          $spans
        }

        match $spans.0 {
          nu => $fish_completer
          git => $fish_completer
          asdf => $fish_completer
          _ => $carapace_completer
        } | do $in $spans
      }

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
      alias k = kubecolor

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
