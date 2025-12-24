{ lib }:

with lib;

{
  getWeztermTheme =
    colorscheme: variant:
    let
      themeMap = {
        catppuccin = {
          latte = "Catppuccin Latte";
          macchiato = "Catppuccin Macchiato";
        };
        "rose-pine" = {
          dawn = "Rosé Pine Dawn (base16)";
          moon = "Rosé Pine Moon (base16)";
        };
        gruvbox = {
          dark = "Gruvbox dark, hard (base16)";
          light = "Gruvbox light, hard (base16)";
        };
        solarized = {
          dark = "Solarized Dark Higher Contrast (Gogh)";
          light = "Solarized Light (Gogh)";
        };
        nord = {
          dark = "Nord (base16)";
        };
        everforest = {
          dark-hard = "Everforest Dark Hard (Gogh)";
          dark-medium = "Everforest Dark (Gogh)";
          dark-soft = "Everforest Dark Soft (Gogh)";
          light-hard = "Everforest Light Hard (Gogh)";
          light-medium = "Everforest Light (Gogh)";
          light-soft = "Everforest Light Soft (Gogh)";
        };
        kanagawa = {
          lotus = "Kanagawa Lotus (Gogh)";
          wave = "Kanagawa (Gogh)";
          dragon = "Kanagawa Dragon (Gogh)";
        };
        "black-metal" = {
          gorgoroth = "Black Metal (Gorgoroth)";
        };
      };
    in
    if hasAttr colorscheme themeMap && hasAttr variant themeMap.${colorscheme} then
      themeMap.${colorscheme}.${variant}
    else
      "${colorscheme}-${variant}";

  # Neovim - Custom theme system (Stylix disabled)
  getNeovimConfig =
    colorscheme: variant:
    let
      configMap = {
        catppuccin = {
          plugin = "catppuccin/nvim";
          name = "catppuccin";
          setup = "catppuccin";
          colorscheme = "catppuccin";
        };
        "rose-pine" = {
          plugin = "cdmill/neomodern.nvim";
          name = "neomodern";
          setup = "neomodern";
          colorscheme = _variant: "roseprime";
        };
        gruvbox = {
          plugin = "ellisonleao/gruvbox.nvim";
          name = "gruvbox";
          setup = "gruvbox";
          colorscheme = _variant: "gruvbox";
        };
        solarized = {
          plugin = "craftzdog/solarized-osaka.nvim";
          name = "solarized-osaka";
          setup = "solarized-osaka";
          colorscheme = _variant: "solarized-osaka";
        };
        nord = {
          plugin = "EdenEast/nightfox.nvim";
          name = "nightfox";
          setup = "nightfox";
          colorscheme = _variant: "nordfox";
        };
        everforest = {
          plugin = "sainnhe/everforest";
          name = "everforest";
          setup = "everforest";
          colorscheme = _variant: "everforest";
        };
        kanagawa = {
          plugin = "cdmill/neomodern.nvim";
          name = "neomodern";
          setup = "neomodern";
          colorscheme = _variant: "gyokuro";
        };
        "black-metal" = {
          plugin = "metalelf0/black-metal-theme-neovim";
          name = "black-metal";
          setup = "black-metal";
          colorscheme = _variant: "gorgoroth";
        };
      };
    in
    if hasAttr colorscheme configMap then
      let
        config = configMap.${colorscheme};
        colorschemeValue =
          if isFunction config.colorscheme then config.colorscheme variant else config.colorscheme;
      in
      config // { colorscheme = colorschemeValue; }
    else
      {
        plugin = "${colorscheme}/${colorscheme}.nvim";
        name = colorscheme;
        setup = colorscheme;
        colorscheme = "${colorscheme}-${variant}";
      };

  # Opencode - Uses specific theme identifiers
  getOpencodeTheme =
    colorscheme: _variant:
    let
      themeMap = {
        catppuccin = "catppuccin";
        "rose-pine" = "rosepine";
        gruvbox = "gruvbox";
        solarized = "system";
        nord = "nord";
        everforest = "everforest";
        kanagawa = "kanagawa";
        "black-metal" = "system";
      };
    in
    themeMap.${colorscheme} or colorscheme;

  # Git delta - Not in Stylix, needs theme name
  getDeltaTheme =
    colorscheme: variant:
    let
      # Everforest explicitly uses nord for delta (as seen in palette)
      themeMap = {
        everforest = _v: "nord-dark";
      };
    in
    if hasAttr colorscheme themeMap then
      themeMap.${colorscheme} variant
    else
      "${colorscheme}-${variant}";

  # Atuin - Uses theme name reference
  getAtuinTheme = colorscheme: variant: "${colorscheme}-${variant}";
}
