{
  config,
  pkgs,
  lib,
  ...
}:

let
  themeLib = import ../../shared/theme-colors.nix { inherit lib; };
  themeColors = themeLib.colorsOf config;
  c = themeColors;

  # Every directive is `key=#rrggbb`. tuigreet hands the value to ratatui's
  # `Color::from_str`, which requires the leading `#` and a length of exactly 7,
  # and tuigreet drops any directive that fails to parse. A bare hex therefore
  # made the greeter fall back to its own colours with no error.
  tuigreetTheme = lib.concatStringsSep ";" [
    "container=#${c.base00}"
    "text=#${c.base05}"
    "time=#${c.base04}"
    "greet=#${c.base05}"
    "border=#${c.base0D}"
    "title=#${c.base0D}"
    "prompt=#${c.base04}"
    "input=#${c.base05}"
    "action=#${c.base04}"
    "button=#${c.base0C}"
  ];
in
{
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.tuigreet}/bin/tuigreet --time --time-format '%R' --user-menu --remember --theme '${tuigreetTheme}' --cmd sway-wrapped";
        user = "greeter";
      };
      initial_session = {
        command = "sway-wrapped";
        user = config.sysinit.user.username;
      };
    };
  };

  boot.kernelParams = [
    "quiet"
    "loglevel=3"
    "systemd.show_status=auto"
    "rd.udev.log_level=3"
  ];

  security.pam.services.greetd.enableGnomeKeyring = true;
}
