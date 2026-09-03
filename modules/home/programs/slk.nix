{
  config,
  lib,
  pkgs,
  ...
}:

let
  colors = (import ../../shared/theme-colors.nix { inherit lib; }).colorsOf config;
in

{
  home.packages = [ pkgs.slk ];

  # Custom themes take priority over built-ins. Keep the existing theme name so
  # slk's mutable config can retain workspace state while this file supplies an
  # opaque, terminal-independent palette.
  xdg.configFile."slk/themes/sysinit-ansi-dark.toml".text = ''
    name = "ANSI Dark"

    [colors]
    primary = "#${colors.base0D}"
    accent = "#${colors.base0B}"
    warning = "#${colors.base0A}"
    error = "#${colors.base08}"
    background = "#${colors.base00}"
    surface = "#${colors.base01}"
    surface_dark = "#${colors.base00}"
    text = "#${colors.base05}"
    text_muted = "#${colors.base03}"
    border = "#${colors.base02}"
    sidebar_background = "#${colors.base01}"
    sidebar_text = "#${colors.base05}"
    sidebar_text_muted = "#${colors.base04}"
    rail_background = "#${colors.base00}"
    selection_background = "#${colors.base0D}"
    selection_foreground = "#${colors.base00}"
    search_highlight_bg = "#${colors.base0A}"
    search_highlight_fg = "#${colors.base00}"
  '';
}
