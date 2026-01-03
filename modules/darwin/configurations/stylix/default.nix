{
  pkgs,
  lib,
  values,
  ...
}:

let
  themeConfig = values.theme;

  schemeMapping = {
    "rose-pine" = {
      "moon" = ./schemes/rose-pine-moon.yaml;
      "dawn" = ./schemes/rose-pine-dawn.yaml;
    };
    "catppuccin" = {
      "mocha" = "${pkgs.base16-schemes}/share/themes/catppuccin-mocha.yaml";
      "latte" = "${pkgs.base16-schemes}/share/themes/catppuccin-latte.yaml";
      "frappe" = "${pkgs.base16-schemes}/share/themes/catppuccin-frappe.yaml";
      "macchiato" = "${pkgs.base16-schemes}/share/themes/catppuccin-macchiato.yaml";
    };
    "gruvbox" = {
      "dark" = "${pkgs.base16-schemes}/share/themes/gruvbox-dark-hard.yaml";
      "light" = "${pkgs.base16-schemes}/share/themes/gruvbox-light-hard.yaml";
    };
    "kanagawa" = {
      "lotus" = "${pkgs.base16-schemes}/share/themes/kanagawa.yaml";
      "wave" = "${pkgs.base16-schemes}/share/themes/kanagawa.yaml";
      "dragon" = "${pkgs.base16-schemes}/share/themes/kanagawa.yaml";
    };
    "kanso" = {
      "zen" = "${pkgs.base16-schemes}/share/themes/kanagawa.yaml";
      "ink" = "${pkgs.base16-schemes}/share/themes/kanagawa.yaml";
      "mist" = "${pkgs.base16-schemes}/share/themes/kanagawa.yaml";
      "pearl" = "${pkgs.base16-schemes}/share/themes/kanagawa.yaml";
    };
    "solarized" = {
      "dark" = "${pkgs.base16-schemes}/share/themes/solarized-dark.yaml";
      "light" = "${pkgs.base16-schemes}/share/themes/solarized-light.yaml";
    };
    "nord" = {
      "default" = "${pkgs.base16-schemes}/share/themes/nord.yaml";
      "light" = "${pkgs.base16-schemes}/share/themes/nord.yaml";
    };
    "everforest" = {
      "dark-hard" = "${pkgs.base16-schemes}/share/themes/everforest.yaml";
      "dark-medium" = "${pkgs.base16-schemes}/share/themes/everforest.yaml";
      "dark-soft" = "${pkgs.base16-schemes}/share/themes/everforest.yaml";
      "light-hard" = "${pkgs.base16-schemes}/share/themes/everforest.yaml";
      "light-medium" = "${pkgs.base16-schemes}/share/themes/everforest.yaml";
      "light-soft" = "${pkgs.base16-schemes}/share/themes/everforest.yaml";
    };
    "black-metal" = {
      "gorgoroth" = "${pkgs.base16-schemes}/share/themes/black-metal.yaml";
    };
  };

  selectedScheme =
    if lib.hasAttrByPath [ themeConfig.colorscheme themeConfig.variant ] schemeMapping then
      schemeMapping.${themeConfig.colorscheme}.${themeConfig.variant}
    else
      throw "No base16 scheme found for theme '${themeConfig.colorscheme}' variant '${themeConfig.variant}'";

  polarityValue = if themeConfig.appearance == "light" then "light" else "dark";

  monospaceFontName = themeConfig.font.monospace;

in
{
  stylix = {
    enable = true;
    autoEnable = true;

    polarity = polarityValue;
    base16Scheme = selectedScheme;

    fonts = {
      monospace = {
        name = monospaceFontName;
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

    opacity = {
      terminal = themeConfig.transparency.opacity;
      applications = themeConfig.transparency.opacity;
      desktop = 1.0;
      popups = themeConfig.transparency.opacity;
    };

    targets = {
      jankyborders.enable = true;
    };
  };
}
