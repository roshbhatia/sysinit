{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  theme = config.sysinit.theme;
  themeLib = import ../../../shared/theme-colors.nix { inherit lib; };
  palette = import ../../../shared/terminal-palette.nix (themeLib.colorsOf config);
  paths = import ../../../lib/paths.nix { inherit lib; };
  path = paths.getPathString config.home.username config.home.homeDirectory;
  shell = lib.optionals (config.programs.nushell.enable or false) (
    [
      "/usr/bin/env"
      "-u"
      "PWD"
      "PATH=${path}"
    ]
    ++ import ../../../shared/terminal-shell.nix config
  );
  picker = import ../../../shared/terminal-providers.nix {
    inherit
      config
      inputs
      lib
      pkgs
      ;
  };
  themeFile = pkgs.writeText "Sysinit" (
    ''
      foreground = ${palette.foreground}
      background = ${palette.background}
      cursor-color = ${palette.cursor_bg}
      cursor-text = ${palette.cursor_fg}
      selection-background = ${palette.selection_bg}
      selection-foreground = ${palette.selection_fg}
    ''
    + lib.concatStringsSep "\n" (
      lib.imap0 (index: color: "palette = ${toString index}=${color}") (palette.ansi ++ palette.brights)
    )
    + "\n"
  );
  settings = builtins.toJSON {
    inherit (theme) appearance;
    inherit (theme.font) monospace size symbols;
    inherit path shell picker;
    inherit (config.home) homeDirectory;
    themeFile = "${config.xdg.configHome}/rex/themes/Sysinit";
    startupCommand = lib.escapeShellArgs shell;
  };
in
{
  options.sysinit.rex.enable = lib.mkEnableOption "Rex terminal with sysinit key bindings and appearance";

  config = lib.mkIf config.sysinit.rex.enable {
    home.packages = [
      pkgs.rex
    ]
    ++ lib.optionals pkgs.stdenv.hostPlatform.isAarch64 [
      inputs.neorex.packages.${pkgs.stdenv.hostPlatform.system}.default
    ];
    sysinit.codesign.protectRunningApps = [ "Rex" ];
    xdg.configFile = {
      "rex/themes/Sysinit".source = themeFile;
      "rex/init.lua".text = builtins.readFile ./init.lua + ''

        local settings = rex.json.decode(${builtins.toJSON settings})
        local layout = dofile("${./layout.lua}")(settings)
        dofile("${./appearance.lua}")(settings)
        dofile("${./floating.lua}")(settings, layout)
        dofile("${./sessions.lua}")(settings, layout)
      '';
    };
  };
}
