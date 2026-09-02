{
  config,
  lib,
  pkgs,
  ...
}:
let
  shell = import ../../../lib/shell.nix { inherit lib; };
  paths_lib = import ../../../lib/paths.nix { inherit config lib; };

  pathsList = paths_lib.getAllPaths config.home.username config.home.homeDirectory;
  carapaceBin = "${pkgs.carapace}/bin/carapace";
  fishBin = "${pkgs.fish}/bin/fish";

  # home.sessionVariables reaches bash, zsh and fish through hm-session-vars.sh,
  # which nushell cannot source. Without this a nushell pane had no EDITOR, no
  # XDG_*, no LANG and no SYSINIT_PROSE_STYLE, which is why zsh had to stay the
  # pane shell. Carried as JSON so a value needing an escape cannot break the
  # file, and read back with a three-hash raw string so no value can close it.
  #
  # hm-session-vars.sh is a POSIX script, so a value there may hold an expansion
  # that nushell never performs. $HOME is expanded here; TERMINFO_DIRS appends to
  # itself and is rebuilt below; anything else is caught by the assertion, rather
  # than reaching a pane as a literal dollar sign.
  sessionVarsRaw = builtins.mapAttrs (_name: toString) config.home.sessionVariables;

  sessionVarsExpanded = builtins.mapAttrs (
    _name: builtins.replaceStrings [ "$HOME" "\${HOME}" ] (lib.replicate 2 config.home.homeDirectory)
  ) sessionVarsRaw;

  sessionVarsCarried = builtins.removeAttrs sessionVarsExpanded [ "TERMINFO_DIRS" ];

  sessionVarsUnexpanded = lib.filterAttrs (
    _name: value: builtins.match ".*[$].*" value != null
  ) sessionVarsCarried;

  sessionVarsJson = builtins.toJSON sessionVarsCarried;

  # home-manager writes TERMINFO_DIRS as "<before>:$TERMINFO_DIRS${TERMINFO_DIRS:+:}<after>",
  # a self-append guarded by a POSIX conditional. Both sides are read back here so
  # the nushell line keeps the same order without parsing the conditional.
  terminfoSides = lib.splitString "$TERMINFO_DIRS\${TERMINFO_DIRS:+:}" (
    sessionVarsRaw.TERMINFO_DIRS or ""
  );
  terminfoSide =
    index: lib.filter (dir: dir != "") (lib.splitString ":" (lib.elemAt terminfoSides index));
  terminfoBefore = terminfoSide 0;
  terminfoAfter = lib.optionals (lib.length terminfoSides > 1) (terminfoSide 1);
  nuList = dirs: lib.concatMapStringsSep " " (dir: "\"${dir}\"") dirs;

  # vivid costs 10ms per startup for a string that only changes when the theme
  # does. The theme file is already a store path, so the answer is too.
  lsColorsFile = pkgs.runCommand "sysinit-ls-colors" { } ''
    ${pkgs.vivid}/bin/vivid generate ${config.xdg.configFile."vivid/themes/stylix.yml".source} > $out
  '';

  ompConfigFile = pkgs.runCommand "sysinit-oh-my-posh-config.json" { } ''
    ln -s ${config.xdg.configFile."oh-my-posh/config.json".source} $out
  '';

  # `oh-my-posh init nu` without --print writes nothing a shell can source, so
  # home-manager's nushell integration left the stock prompt in place and paid
  # 14ms per startup for it. Baked here, sourced once, measured at 0 subprocesses.
  ompInitFile = pkgs.runCommand "sysinit-omp-init.nu" { } ''
    export HOME=$(mktemp -d)
    ${config.programs.oh-my-posh.package}/bin/oh-my-posh init nu \
      --config ${ompConfigFile} \
      --print > $out
  '';

  functionsFile = pkgs.writeText "sysinit-functions.nu" (
    builtins.replaceStrings [ "@seshySessions@" ] [ config.sysinit.paths.resolved.seshySessions ] (
      builtins.readFile ./functions.nu
    )
  );
in
{
  assertions = [
    {
      assertion = sessionVarsUnexpanded == { };
      message =
        "home.sessionVariables carries a shell expansion nushell cannot perform, so a nushell pane would read it literally: "
        + lib.concatStringsSep ", " (lib.attrNames sessionVarsUnexpanded);
    }
  ];

  home.packages = [ pkgs.nuvim ];

  programs = {
    nushell = {
      enable = true;
      plugins = [ pkgs.nu-plugin-nuvim ];
      # Nushell still opens env.nu when config.nu owns every environment value.
      # A nonempty value makes Home Manager install the required file.
      extraEnv = "# Environment values are generated in config.nu.\n";
      # Home Manager renders shell aliases after extraConfig. Force the shared
      # `ll` alias out so it cannot replace the structured command sourced below.
      shellAliases = lib.mkForce (builtins.removeAttrs shell.commonAliases [ "ll" ]);

      environmentVariables.LS_COLORS = lib.mkForce (
        lib.hm.nushell.mkNushellInline "(open --raw ${lsColorsFile} | str trim)"
      );

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
          # reedline binds no vi-insert Ctrl-U, and `worker` opens every run by
          # sending \025 to clear whatever the pane was holding. Without this the
          # clear is swallowed and the run appends to a half-typed line.
          {
            name = "clear_line";
            modifier = "control";
            keycode = "char_u";
            mode = [
              "emacs"
              "vi_normal"
              "vi_insert"
            ];
            event = {
              edit = "clear";
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

      extraConfig = ''
        use std/util "path add"

        load-env (r###'${sessionVarsJson}'### | from json)

        $env.TERMINFO_DIRS = (
          [${nuList terminfoBefore}]
          | append ($env.TERMINFO_DIRS? | default "" | split row ":")
          | append [${nuList terminfoAfter}]
          | where {|dir| $dir | is-not-empty }
          | uniq
          | str join ":"
        )

        ${lib.concatMapStringsSep "\n" (path: "path add \"${path}\"") pathsList}

        $env.CARAPACE_LENIENT = "1"
        $env.CARAPACE_BRIDGES = "zsh,fish,bash,inshellisense"
        use std/dirs shells-aliases *

        let fish_completer = {|spans: list<string>|
          let command = ($spans | str replace --all "'" "\\'" | str join " ")
          let result = (
            do {
              ${pkgs.coreutils}/bin/timeout 2s ${fishBin} --command $"complete '--do-complete=($command)'"
            }
            | complete
          )

          if $result.exit_code != 0 or ($result.stdout | str trim | is-empty) {
            return null
          }

          try {
            $result.stdout
            | from tsv --flexible --noheaders --no-infer
            | rename value description
            | update value {|row|
              let value = $row.value
              let needs_quote = ["\\" " " "[" "]" "(" ")" "\t" "'" '"' "`"] | any {$in in $value}
              if $needs_quote and ($value | path exists) {
                let expanded = if ($value | str starts-with "~") {
                  $value | path expand --no-symlink
                } else {
                  $value
                }
                $'"($expanded | str replace --all '"' '\\"')"'
              } else {
                $value
              }
            }
          } catch {
            null
          }
        }

        let carapace_completer = {|spans: list<string>|
          let kubectl_alias = $spans.0 in ["k", "kubecolor"]
          let spans = if $kubectl_alias {
            $spans | skip 1 | prepend "kubectl"
          } else {
            $spans
          }

          # Kubectl may query the current cluster for dynamic results. Keep a
          # failed cluster lookup below the delay a key press can expose.
          let completion_timeout = if $kubectl_alias { "0.25s" } else { "3s" }

          let result = (
            do { ${pkgs.coreutils}/bin/timeout $completion_timeout ${carapaceBin} $spans.0 nushell ...$spans }
            | complete
          )

          if $result.exit_code != 0 { return null }

          try { $result.stdout | from json } catch { null }
        }

        let external_completer = {|spans: list<string>|
          let expanded_alias = (
            scope aliases
            | where name == $spans.0
            | get -o 0.expansion
          )
          let spans = if $expanded_alias != null {
            $spans
            | skip 1
            | prepend ($expanded_alias | split row " " | take 1)
          } else {
            $spans
          }

          let primary = match $spans.0 {
            nu | git => (do $fish_completer $spans)
            _ => (do $carapace_completer $spans)
          }

          if $primary == null or ($primary | is-empty) {
            do $fish_completer $spans
          } else {
            $primary
          }
        }

        $env.config.completions.external.enable = true
        $env.config.completions.external.max_results = 100
        $env.config.completions.external.completer = $external_completer

        source ${ompInitFile}
        # The baked script pins the id it was built with, so every pane would
        # otherwise report one shared prompt session to oh-my-posh.
        $env.POSH_SESSION_ID = (random uuid)

        source ${functionsFile}

        ${lib.optionalString pkgs.stdenv.hostPlatform.isDarwin ''
          alias nu-open = open
          alias open = ^open
        ''}
      '';
    };

    # Fish stays available as Nushell's completion database. It is not the login
    # shell. Carapace is configured above so its generated shell init cannot
    # replace the timeout and fallback policy. Fish otherwise enables man caches
    # by default, but current Darwin profiles have no man package to build them.
    man.generateCaches = false;
    fish.enable = true;
    carapace = {
      enable = true;
      enableBashIntegration = false;
      enableFishIntegration = false;
      enableNushellIntegration = false;
      enableZshIntegration = false;
    };

    eza.enableNushellIntegration = lib.mkForce false;
  };
}
