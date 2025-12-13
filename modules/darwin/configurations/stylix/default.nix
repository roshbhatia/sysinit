{
  pkgs,
  ...
}:

{
  stylix.enable = true;
  stylix.autoEnable = true;
  stylix.polarity = "dark";

  stylix.base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-macchiato.yaml";

  stylix.fonts = {
    monospace = {
      name = "Agave Nerd Font";
      package = pkgs.nerd-fonts.agave;
    };
    sansSerif = {
      name = "DejaVu Sans";
      package = pkgs.dejavu_fonts;
    };
    serif = {
      name = "DejaVu Serif";
      package = pkgs.dejavu_fonts;
    };
    sizes = {
      terminal = 11;
      applications = 11;
      desktop = 11;
      popups = 11;
    };
  };

  stylix.targets = {
    jankyborders.enable = true;
  };
}
