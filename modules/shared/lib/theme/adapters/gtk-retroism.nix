{ lib }:

palette:

let
  utils = import ../core/utils.nix { inherit lib; };
  semanticColors = utils.createSemanticMapping palette;
in

{
  # GTK theme settings for retroism
  # These configure the gtk.extraConfig with retroism-appropriate settings
  
  themeName = "ClassicPlatinumStreamlined";
  
  # GTK configuration
  gtk3Settings = {
    gtk-application-prefer-dark-theme = true;
    gtk-icon-theme-name = "RetroismIcons";
    gtk-theme-name = "ClassicPlatinumStreamlined";
    gtk-font-name = "Monospace 10";
  };

  # Cursor theme
  cursorTheme = {
    name = "Adwaita";
    size = 24;
  };

  # Icon theme
  iconTheme = {
    name = "RetroismIcons";
    package = null; # Will be provided by system
  };

  # CSS styling for gtk apps
  gtkCss = ''
    @define-color bg_color ${palette.bg0};
    @define-color fg_color ${palette.fg0};
    @define-color base_color ${palette.bg1};
    @define-color text_color ${palette.fg0};
    @define-color selected_bg_color ${palette.accent};
    @define-color selected_fg_color ${palette.bg0};
    @define-color tooltip_bg_color ${palette.bg2};
    @define-color tooltip_fg_color ${palette.fg0};
    @define-color link_color ${palette.cyan};
    @define-color success_color ${palette.green};
    @define-color warning_color ${palette.yellow};
    @define-color error_color ${palette.red};
  '';
}
