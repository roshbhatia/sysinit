{
  config,
  lib,
  pkgs,
  ...
}:
let
  theme = config.sysinit.theme;
  themeLib = import ../../../shared/theme-colors.nix { inherit lib; };
  palette = import ../../../shared/terminal-palette.nix (themeLib.colorsOf config);
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
  settings = builtins.toJSON (
    {
      inherit (theme) appearance;
      inherit (theme.font) monospace size symbols;
      themeFile = "${config.xdg.configHome}/rex/themes/Sysinit";
    }
    // lib.optionalAttrs (config.programs.nushell.enable or false) {
      shell = lib.escapeShellArgs (import ../../../shared/terminal-shell.nix config);
    }
  );
in
{
  options.sysinit.rex.enable = lib.mkEnableOption "Rex terminal with sysinit key bindings and appearance";

  config = lib.mkIf config.sysinit.rex.enable {
    home.packages = [ pkgs.rex ];
    sysinit.codesign.protectRunningApps = [ "Rex" ];
    xdg.configFile = {
      "rex/themes/Sysinit".source = themeFile;
      "rex/init.lua".text = builtins.readFile ./init.lua + ''

        dofile("${./appearance.lua}")(rex.json.decode(${builtins.toJSON settings}))
      '';
    };
  };
}
