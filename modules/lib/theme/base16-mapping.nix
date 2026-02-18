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

  rose-pine = {
    dawn = "${schemesPath}/rose-pine-dawn.yaml";
    moon = "${schemesPath}/rose-pine-moon.yaml";
    main = "${schemesPath}/rose-pine.yaml";
  };

  everforest = {
    dark-soft = "${schemesPath}/everforest.yaml";
    dark-medium = "${schemesPath}/everforest-dark-medium.yaml";
    dark-hard = "${schemesPath}/everforest-dark-hard.yaml";
    light-soft = "${customPath}/everforest-light-soft.yaml";
    light-medium = "${customPath}/everforest-light-medium.yaml";
    light-hard = "${customPath}/everforest-light-hard.yaml";
  };
}
