{
  pkgs,
  lib,
  values,
  ...
}:

let
  themeLib = import ../../shared/lib/theme.nix { inherit lib; };
  themeConfig = values.theme;

  # Get base16 scheme path (upstream or custom YAML)
  schemePath = themeLib.getBase16SchemePath pkgs themeConfig.colorscheme themeConfig.variant;
in
{
  stylix = {
    enable = true;
    autoEnable = true;
    enableReleaseChecks = false;

    polarity = themeConfig.appearance;
    base16Scheme = schemePath;

    fonts = {
      monospace.name = themeConfig.font.monospace;
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

    opacity = {
      terminal = themeConfig.transparency.opacity;
      applications = themeConfig.transparency.opacity;
      desktop = themeConfig.transparency.opacity;
      popups = themeConfig.transparency.opacity;
    };

    targets.jankyborders.enable = true;
  };
}
