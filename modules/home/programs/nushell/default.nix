{
  config,
  lib,
  pkgs,
  ...
}:
let
  shell = import ../../../lib/shell.nix { inherit lib; };
  paths_lib = import ../../../lib/paths.nix { inherit lib; };
  nushellLib = import ./lib.nix { inherit lib; };

  pathsList = paths_lib.getAllPaths config.home.username config.home.homeDirectory;
  carapaceBin = "${pkgs.carapace}/bin/carapace";
  fishBin = "${pkgs.fish}/bin/fish";

  sessionVarsRaw = builtins.mapAttrs (_name: toString) config.home.sessionVariables;

  sessionVarsExpanded = builtins.mapAttrs (
    _name: builtins.replaceStrings [ "$HOME" "\${HOME}" ] (lib.replicate 2 config.home.homeDirectory)
  ) sessionVarsRaw;

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

  nuList = nushellLib.arguments;

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

  home.activation.sysinitNusecrets = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    SECRETS="${config.home.homeDirectory}/.nusecrets.nu"
    if [ ! -e "$SECRETS" ]; then
      (umask 077; printf '# nu code, sourced by every nushell start; keep it parseable\n' > "$SECRETS")
    fi
  '';

  programs = {
    nushell = {
      enable = true;
      plugins = [ pkgs.nu-plugin-nuvim ];

      extraEnv = "# Environment values are generated in config.nu.\n";

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

        # source resolves at parse time, so the file cannot be optional in the
        # config itself. The activation below creates an empty ~/.nusecrets.nu
        # when missing; deleting it afterwards breaks shell startup until the
        # next switch recreates it.
        source ~/.nusecrets.nu

        ${nushellLib.pathAdd pathsList}

        ${nushellLib.sourceCompletion pkgs.seshy "sy"}
        ${nushellLib.sourceCompletion pkgs.tether "tether"}
        ${nushellLib.sourceCompletion pkgs.tether "tsh"}

        use std/dirs
        use std/dirs shells-aliases *

        ${completersConfig}

        source ${ompInitFile}
        # The baked script pins the id it was built with, so every pane would
        # otherwise report one shared prompt session to oh-my-posh.
        $env.POSH_SESSION_ID = (random uuid)

        use ${functionsFile} *
        use ${./onepassword.nu} *

        ${lib.optionalString pkgs.stdenv.hostPlatform.isDarwin ''
          alias nu-open = open
          alias open = ^open
        ''}
      '';
    };

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
