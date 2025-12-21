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
  # Note: ClassicPlatinumStreamlined and RetroismIcons must be installed manually
  # Place in ~/.local/share/themes/ and ~/.local/share/icons/
  gtk = {
    enable = lib.mkForce true;
    
    theme = {
      # Use Adwaita as fallback until ClassicPlatinumStreamlined is installed
      name = lib.mkForce "Adwaita";
    };
    
    iconTheme = {
      # Use Adwaita as fallback until RetroismIcons is installed
      name = lib.mkForce "Adwaita";
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
      # These will be overridden manually when ClassicPlatinumStreamlined is installed
      gtk-theme = lib.mkForce "Adwaita";
      icon-theme = lib.mkForce "Adwaita";
      cursor-theme = lib.mkForce "Adwaita";
      font-name = lib.mkForce "${values.theme.font.monospace} 10";
      monospace-font-name = lib.mkForce "${values.theme.font.monospace} 10";
    };
    
    # Additional tweaks for terminal-friendly environment
    "org/gnome/desktop/wm/preferences" = {
      button-layout = lib.mkForce "appmenu:minimize,maximize,close";
    };
  };

  # TODO: Manual installation of retro themes
  # 1. Download ClassicPlatinumStreamlined: https://github.com/diinki/linux-retroism/tree/main/gtk_theme
  # 2. Download RetroismIcons: https://github.com/diinki/linux-retroism/tree/main/icon_theme
  # 3. Install to ~/.local/share/themes/ and ~/.local/share/icons/
  # 4. Update dconf settings: gtk-theme and icon-theme to retroism values
  # 5. Run: dconf write /org/gnome/desktop/interface/gtk-theme "'ClassicPlatinumStreamlined'"
}
