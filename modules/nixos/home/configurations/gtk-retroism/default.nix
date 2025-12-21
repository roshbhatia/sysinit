{
  lib,
  values,
  ...
}:

let
  themes = import ../../../../shared/lib/theme { inherit lib; };
  theme = themes.getTheme values.theme.colorscheme;
  gtkAdapter = import ../../../../shared/lib/theme/adapters/gtk-retroism.nix { inherit lib; };
  gtkConfig = gtkAdapter theme.palettes.${values.theme.variant};
in

{
  # GTK theme configuration for retroism
  gtk = {
    enable = lib.mkForce true;
    
    theme = {
      name = lib.mkForce "ClassicPlatinumStreamlined";
      package = null; # Provided by system or installed manually
    };
    
    iconTheme = {
      name = lib.mkForce "RetroismIcons";
      package = null; # Provided by system or installed manually
    };
    
    cursorTheme = {
      name = lib.mkForce "Adwaita";
      size = 24;
    };
    
    font = {
      name = lib.mkForce values.theme.font.monospace;
      size = lib.mkForce 10;
    };
  };

  # GNOME/dconf settings for theme application
  dconf.settings = {
    "org/gnome/desktop/interface" = {
      gtk-theme = "ClassicPlatinumStreamlined";
      icon-theme = "RetroismIcons";
      cursor-theme = "Adwaita";
      font-name = "${values.theme.font.monospace} 10";
      monospace-font-name = "${values.theme.font.monospace} 10";
    };
    
    # Additional GNOME tweaks for retro aesthetic
    "org/gnome/desktop/wm/preferences" = {
      button-layout = "appmenu:minimize,maximize,close";
    };
  };

  # TODO: Install ClassicPlatinumStreamlined and RetroismIcons themes
  # Place in ~/.local/share/themes/ and ~/.local/share/icons/
}
