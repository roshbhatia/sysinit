{ lib, ... }:

let
  utils = import ../core/utils.nix { inherit lib; };
in
{
  meta = {
    name = "Nord";
    id = "nord";
    variants = [ "dark" ];
    supports = [ "dark" ];
    author = "Arctic Ice Studio";
    homepage = "https://www.nordtheme.com/";
  };

  palettes = {
    dark = utils.validatePalette {

      nord0 = "#2e3440";
      nord1 = "#3b4252";
      nord2 = "#434c5e";
      nord3 = "#4c566a";

      nord4 = "#d8dee9";
      nord5 = "#e5e9f0";
      nord6 = "#eceff4";

      nord7 = "#8fbcbb";
      nord8 = "#88c0d0";
      nord9 = "#81a1c1";
      nord10 = "#5e81ac";

      nord11 = "#bf616a";
      nord12 = "#d08770";
      nord13 = "#ebcb8b";
      nord14 = "#a3be8c";
      nord15 = "#b48ead";

      base = "#2e3440";
      bg = "#2e3440";
      bg_alt = "#3b4252";
      surface = "#434c5e";
      surface_alt = "#4c566a";
      text = "#eceff4";
      fg = "#eceff4";
      fg_alt = "#e5e9f0";
      comment = "#4c566a";
      blue = "#5e81ac";
      cyan = "#88c0d0";
      teal = "#8fbcbb";
      green = "#a3be8c";
      yellow = "#ebcb8b";
      orange = "#d08770";
      red = "#bf616a";
      purple = "#b48ead";
      accent = "#5e81ac";
      accent_dim = "#434c5e";
    };
  };

  semanticMapping = palette: utils.createSemanticMapping palette;

  appAdapters = {
    wezterm = {
      dark = "Nord (base16)";
    };

    neovim = {
      plugin = "EdenEast/nightfox.nvim";
      name = "nightfox";
      setup = "nightfox";
      colorscheme = _variant: "nordfox";
    };

    bat = variant: "nord-${variant}";
    delta = variant: "nord-${variant}";
    atuin = variant: "nord-${variant}";
    vivid = _variant: "nord";
    k9s = variant: "nord-${variant}";
    helix = _variant: "nord";
    nushell = variant: "nord-${variant}.nu";
  };
}
