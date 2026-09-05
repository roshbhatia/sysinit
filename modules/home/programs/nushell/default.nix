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

  # A colon-list variable appends to itself through a POSIX conditional, in two
  # shapes: home-manager writes TERMINFO_DIRS as "<before>:$VAR${VAR:+:}<after>",
  # and stylix writes XDG_CONFIG_DIRS as "<before>${VAR:+:$VAR}". Nushell performs
  # neither, so each is split on its self-reference and rebuilt below in order.
  selfAppendPatterns = name: [
    "\$${name}\${${name}:+:}"
    "\${${name}:+:\$${name}}"
  ];

  splitSelfAppend =
    name: value:
    let
      matched = lib.filter (pattern: lib.hasInfix pattern value) (selfAppendPatterns name);
    in
    if matched == [ ] then
      null
    else
      let
        sides = lib.splitString (lib.head matched) value;
        side = index: lib.filter (dir: dir != "") (lib.splitString ":" (lib.elemAt sides index));
      in
      {
        before = side 0;
        after = lib.optionals (lib.length sides > 1) (side 1);
      };

  selfAppendVars = lib.filterAttrs (_name: sides: sides != null) (
    builtins.mapAttrs splitSelfAppend sessionVarsExpanded
  );

  sessionVarsCarried = builtins.removeAttrs sessionVarsExpanded (lib.attrNames selfAppendVars);

  sessionVarsUnexpanded = lib.filterAttrs (
    _name: value: builtins.match ".*[$].*" value != null
  ) sessionVarsCarried;

  sessionVarsJson = builtins.toJSON sessionVarsCarried;

  nuList = dirs: lib.concatMapStringsSep " " (dir: "\"${dir}\"") dirs;

  selfAppendLines = lib.concatStringsSep "\n" (
    lib.mapAttrsToList (name: sides: ''
      $env.${name} = (
        [${nuList sides.before}]
        | append ($env.${name}? | default "" | split row ":")
        | append [${nuList sides.after}]
        | where {|dir| $dir | is-not-empty }
        | uniq
        | str join ":"
      )
    '') selfAppendVars
  );

  vividThemeSource =
    if config.programs.vivid.activeTheme == null then
      null
    else
      lib.attrByPath [
        "vivid/themes/${config.programs.vivid.activeTheme}.yml"
        "source"
      ] null config.xdg.configFile;

  # vivid costs 10ms per startup for a string that only changes when the theme
  # does. The theme file is already a store path, so the answer is too.
  lsColorsFile =
    if vividThemeSource == null then
      null
    else
      pkgs.runCommand "sysinit-ls-colors" { } ''
        ${pkgs.vivid}/bin/vivid generate ${vividThemeSource} > $out
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
    builtins.replaceStrings
      [
        "@seshySessions@"
        "@timeout@"
      ]
      [
        config.sysinit.paths.resolved.seshySessions
        "${pkgs.coreutils}/bin/timeout"
      ]
      (builtins.readFile ./functions.nu)
  );

  completersConfig =
    builtins.replaceStrings
      [
        "@timeout@"
        "@fish@"
        "@carapace@"
      ]
      [
        "${pkgs.coreutils}/bin/timeout"
        fishBin
        carapaceBin
      ]
      (builtins.readFile ./completers.nu.tmpl);
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

      environmentVariables = lib.optionalAttrs (lsColorsFile != null) {
        LS_COLORS = lib.mkForce (lib.hm.nushell.mkNushellInline "(open --raw ${lsColorsFile} | str trim)");
      };

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

        ${selfAppendLines}

        ${lib.concatMapStringsSep "\n" (path: "path add \"${path}\"") pathsList}

        use std/dirs shells-aliases *

        ${completersConfig}

        source ${ompInitFile}
        # The baked script pins the id it was built with, so every pane would
        # otherwise report one shared prompt session to oh-my-posh.
        $env.POSH_SESSION_ID = (random uuid)

        use ${functionsFile} *

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
