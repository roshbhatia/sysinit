{
  lib,
  values,
  ...
}:

{
  # Environment configuration for retroism aesthetic
  # Uses available nixpkgs themes and dconf for consistent appearance
  
  # Font configuration
  home.file.".config/fontconfig/conf.d/30-retroism-fonts.conf" = {
    text = ''
      <?xml version="1.0"?>
      <!DOCTYPE fontconfig SYSTEM "fonts.dtd">
      <fontconfig>
        <!-- Retroism font preferences -->
        <alias binding="same">
          <family>monospace</family>
          <prefer>
            <family>${values.theme.font.monospace}</family>
          </prefer>
        </alias>
        
        <match target="font">
          <edit name="antialias" mode="assign">
            <bool>true</bool>
          </edit>
          <edit name="hinting" mode="assign">
            <bool>true</bool>
          </edit>
        </match>
      </fontconfig>
    '';
  };

  # Minimal dconf settings for consistent environment
  dconf.settings = {
    "org/gnome/desktop/interface" = {
      # Use system defaults, styling done via Hyprland/Wezterm colors
      font-name = "${values.theme.font.monospace} 10";
      monospace-font-name = "${values.theme.font.monospace} 10";
    };
  };
}
