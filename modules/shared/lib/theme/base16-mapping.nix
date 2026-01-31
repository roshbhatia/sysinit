{ pkgs }:
let
  schemesPath = "${pkgs.base16-schemes}/share/themes";
  customPath = ./custom-schemes;
in
{
  catppuccin = {
    latte = "${schemesPath}/catppuccin-latte.yaml";
    macchiato = "${schemesPath}/catppuccin-macchiato.yaml";
    mocha = "${schemesPath}/catppuccin-mocha.yaml";
    frappe = "${schemesPath}/catppuccin-frappe.yaml";
  };

  gruvbox = {
    dark = "${schemesPath}/gruvbox-dark-hard.yaml";
    light = "${schemesPath}/gruvbox-light-hard.yaml";
  };

  kanagawa = {
    wave = "${schemesPath}/kanagawa.yaml";
    dragon = "${schemesPath}/kanagawa-dragon.yaml";
    lotus = "${customPath}/kanagawa-lotus.yaml";
  };

  rose-pine = {
    dawn = "${schemesPath}/rose-pine-dawn.yaml";
    moon = "${schemesPath}/rose-pine-moon.yaml";
    main = "${schemesPath}/rose-pine.yaml";
  };

  solarized = {
    dark = "${schemesPath}/solarized-dark.yaml";
    light = "${schemesPath}/solarized-light.yaml";
  };

  nord = {
    default = "${schemesPath}/nord.yaml";
    light = "${schemesPath}/nord-light.yaml";
  };

  everforest = {
    dark-soft = "${schemesPath}/everforest.yaml";
    dark-medium = "${schemesPath}/everforest-dark-medium.yaml";
    dark-hard = "${schemesPath}/everforest-dark-hard.yaml";
    light-soft = "${customPath}/everforest-light-soft.yaml";
    light-medium = "${customPath}/everforest-light-medium.yaml";
    light-hard = "${customPath}/everforest-light-hard.yaml";
  };

  black-metal = {
    nile = "${schemesPath}/black-metal-nile.yaml";
    gorgoroth = "${schemesPath}/black-metal-gorgoroth.yaml";
    morbid = "${schemesPath}/black-metal-morbid.yaml";
  };

  tokyonight = {
    night = "${schemesPath}/tokyo-night-dark.yaml";
    storm = "${schemesPath}/tokyo-night-storm.yaml";
    day = "${schemesPath}/tokyo-night-light.yaml";
  };

  monokai = {
    default = "${schemesPath}/monokai.yaml";
  };

  flexoki = {
    dark = "${schemesPath}/flexoki-dark.yaml";
    light = "${schemesPath}/flexoki-light.yaml";
  };

  # Custom themes (not in base16-schemes)
  kanso = {
    zen = "${customPath}/kanso-zen.yaml";
    ink = "${customPath}/kanso-ink.yaml";
    mist = "${customPath}/kanso-mist.yaml";
    pearl = "${customPath}/kanso-pearl.yaml";
  };

  retroism = {
    dark = "${customPath}/retroism-dark.yaml";
    amber = "${customPath}/retroism-amber.yaml";
    green = "${customPath}/retroism-green.yaml";
  };

  apple-system-colors = {
    light = "${customPath}/apple-system-colors-light.yaml";
  };
}
