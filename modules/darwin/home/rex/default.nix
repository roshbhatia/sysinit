{
  config,
  lib,
  pkgs,
  profile ? "workstation",
  ...
}:

let
  paths = import ../../../lib/paths.nix { inherit lib; };
  profilePath = paths.getPathString config.home.username config.home.homeDirectory;
  themeColors = (import ../../../shared/theme-colors.nix { inherit lib; }).colorsOf config;
  palette = import ../../../shared/terminal-palette.nix themeColors;
  themeFile = pkgs.writeText "Sysinit" (
    ''
      foreground = ${palette.foreground}
      background = ${palette.background}
      cursor-color = ${palette.cursor_bg}
      cursor-text = ${palette.cursor_fg}
      selection-background = ${palette.selection_bg}
      selection-foreground = ${palette.selection_fg}
    ''
    + lib.concatStrings (
      lib.imap0 (index: color: "palette = ${toString index}=${color}\n") (palette.ansi ++ palette.brights)
    )
  );
  shell = import ../../../shared/terminal-shell.nix config;
  editor = pkgs.writeShellScript "rex-review-editor" ''
    export PATH=${lib.escapeShellArg profilePath}
    exec ${lib.escapeShellArg "${config.home.profileDirectory}/bin/nvim"} "$@"
  '';
  settings = {
    # Rex can pass a trailing slash in PWD, which Nushell rejects.
    shell = lib.escapeShellArgs (
      [
        "/usr/bin/env"
        "-u"
        "PWD"
        "PATH=${profilePath}"
      ]
      ++ shell
    );
    themeFile = "${config.xdg.configHome}/rex/themes/Sysinit";
    transparent = config.sysinit.theme.transparency.enable;
    inherit (config.sysinit.theme) appearance;
    inherit (config.sysinit.theme.font) monospace size symbols;
  };
in
{
  options.sysinit.rex.enable = lib.mkOption {
    type = lib.types.bool;
    default = profile == "workstation";
    description = "Install the Rex macOS preview alongside WezTerm.";
  };

  config = lib.mkIf config.sysinit.rex.enable {
    home.packages = [ pkgs.rex ];
    sysinit.codesign.protectRunningApps = [ "Rex" ];
    xdg.configFile = {
      "rex/themes/Sysinit".source = themeFile;
      "rex/init.lua".text = ''
        local settings = rex.json.decode(${builtins.toJSON (builtins.toJSON settings)})
        local reviewr = dofile("${pkgs.sysinit-reviewr}/rex/reviewr/init.lua")
        reviewr.setup({ nvim = "${editor}", command = "lua vim.schedule(vim.cmd.ReviewrOpen)" })
        dofile("${./client.lua}")(rex, settings)
      '';
    };
  };
}
