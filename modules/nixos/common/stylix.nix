{
  config,
  lib,
  pkgs,
  ...
}:

let
  themes = import ../../lib/theme.nix { inherit lib; };
  # Get the colorscheme and variant from sysinit options
  colorscheme = config.sysinit.theme.colorscheme;
  variant = config.sysinit.theme.variant;
in
{
  stylix = {
    enable = true;
    autoEnable = true;
    
    # Use the base16 scheme path from theme metadata
    base16Scheme = themes.getBase16SchemePath pkgs colorscheme variant;
    
    # Use a valid image from the remote host to avoid ImageMagick errors
    image = ./. + "/../../home/firefox/brave-icons/brave.png";

    fonts = {
      monospace = {
        package = pkgs.nerd-fonts.iosevka;
        name = "Iosevka Nerd Font";
      };
      sansSerif = {
        package = pkgs.dejavu_fonts;
        name = "DejaVu Sans";
      };
      serif = {
        package = pkgs.dejavu_fonts;
        name = "DejaVu Serif";
      };
    };
  };
}
