{
  lib,
  values,
  pkgs,
  ...
}:

{
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

  dconf.settings = {
    "org/gnome/desktop/interface" = {
      font-name = lib.mkForce "${values.theme.font.monospace} 10";
      monospace-font-name = lib.mkForce "${values.theme.font.monospace} 10";
      gtk-theme = "Adwaita-dark";
      icon-theme = "Adwaita";
      cursor-theme = "Adwaita";
      gtk-decoration-layout = "close,minimize,maximize:";
    };

    "org/gnome/desktop/wm/preferences" = {
      theme = "Adwaita-dark";
      button-layout = "close,minimize,maximize:";
      titlebar-font = "${values.theme.font.monospace} 10";
    };

  };

  gtk = {
    enable = true;
    theme = {
      name = lib.mkForce "Adwaita-dark";
      package = lib.mkForce pkgs.gnome-themes-extra;
    };
    iconTheme = {
      name = "Adwaita";
      package = pkgs.adwaita-icon-theme;
    };
    cursorTheme = {
      name = "Adwaita";
      package = pkgs.adwaita-icon-theme;
    };
    font = {
      name = lib.mkForce values.theme.font.monospace;
      size = lib.mkForce 10;
    };
    gtk3.extraConfig = {
      gtk-decoration-resize = true;
      gtk-dialogs-use-header = true;
    };
  };
}
