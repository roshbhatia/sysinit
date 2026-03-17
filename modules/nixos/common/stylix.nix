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
    
    # Minimal placeholder image for Stylix (required field)
    image = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";

    fonts = {
      monospace = {
        package = pkgs.maple-mono.NF;
        name = "Maple Mono NF";
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

  fonts.packages = [
    pkgs.ioskeleyMono
    pkgs.commitMono
    pkgs.nerd-fonts.symbols-only
  ];
}
