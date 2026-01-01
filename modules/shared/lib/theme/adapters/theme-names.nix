{ lib }:

with lib;

let
  appMetadata = {
    neovim = {
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
        colorscheme = "roseprime";
      };
      gruvbox = {
        plugin = "ellisonleao/gruvbox.nvim";
        name = "gruvbox";
        setup = "gruvbox";
        colorscheme = "gruvbox";
      };
      solarized = {
        plugin = "craftzdog/solarized-osaka.nvim";
        name = "solarized-osaka";
        setup = "solarized-osaka";
        colorscheme = "solarized-osaka";
      };
      nord = {
        plugin = "EdenEast/nightfox.nvim";
        name = "nightfox";
        setup = "nightfox";
        colorscheme = "nordfox";
      };
      everforest = {
        plugin = "sainnhe/everforest";
        name = "everforest";
        setup = "everforest";
        colorscheme = "everforest";
      };
      kanagawa = {
        plugin = "cdmill/neomodern.nvim";
        name = "neomodern";
        setup = "neomodern";
        colorscheme = "gyokuro";
      };
      "black-metal" = {
        plugin = "metalelf0/black-metal-theme-neovim";
        name = "black-metal";
        setup = "black-metal";
        colorscheme = "gorgoroth";
      };
    };
    wezterm = {
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
        default = "Nord (base16)";
        light = "Nord Light (base16)";
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
    atuin = {
      catppuccin = {
        latte = "catppuccin-latte";
        macchiato = "catppuccin-macchiato";
      };
      "rose-pine" = {
        dawn = "rose-pine";
        moon = "rose-pine";
      };
      gruvbox = {
        dark = "gruvbox";
        light = "gruvbox";
      };
      solarized = {
        dark = "solarized-dark";
        light = "solarized-light";
      };
      nord = {
        default = "nord";
        light = "nord";
      };
      everforest = {
        dark-hard = "everforest";
        dark-medium = "everforest";
        dark-soft = "everforest";
        light-hard = "everforest";
        light-medium = "everforest";
        light-soft = "everforest";
      };
      kanagawa = {
        lotus = "kanagawa";
        wave = "kanagawa";
        dragon = "kanagawa";
      };
      "black-metal" = {
        gorgoroth = "black-metal";
      };
    };
  };
  getAppMetadata =
    app: colorscheme: variant: fallback:
    let
      appMap = appMetadata.${app} or { };
      themeMap = appMap.${colorscheme} or { };
      result = themeMap.${variant} or fallback;
    in
    result;

  getWeztermTheme =
    colorscheme: variant: getAppMetadata "wezterm" colorscheme variant "${colorscheme}-${variant}";

  getNeovimMetadata =
    colorscheme: variant:
    getAppMetadata "neovim" colorscheme variant {
      plugin = "${colorscheme}/${colorscheme}.nvim";
      name = colorscheme;
      setup = colorscheme;
      colorscheme = "${colorscheme}-${variant}";
    };

  getAtuinTheme =
    colorscheme: variant: getAppMetadata "atuin" colorscheme variant "${colorscheme}-${variant}";
in

{
  inherit
    getAppMetadata
    getWeztermTheme
    getNeovimMetadata
    getAtuinTheme
    ;
}
