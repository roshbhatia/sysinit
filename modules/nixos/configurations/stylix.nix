{
  pkgs,
  lib,
  config,
  ...
}:

let
  themeLib = import ../../lib/theme.nix { inherit lib; };
  themeConfig = config.sysinit.theme;

  # Get base16 scheme path (upstream or custom YAML)
  schemePath = themeLib.getBase16SchemePath pkgs themeConfig.colorscheme themeConfig.variant;
in
{
  stylix = {
    enable = true;

    polarity = themeConfig.appearance;
    base16Scheme = schemePath;

    # Disable desktop-related targets for headless/server systems
    targets = {
      gnome.enable = false;
      gtk.enable = false;
    };

    fonts = {
      monospace.name = themeConfig.font.monospace;
      sansSerif.name = themeConfig.font.monospace;
      serif.name = themeConfig.font.monospace;
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
      popups = themeConfig.transparency.opacity;
    };
  };
}
