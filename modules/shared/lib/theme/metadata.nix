{ lib }:
{
  catppuccin = {
    name = "Catppuccin";
    id = "catppuccin";
    variants = [
      "latte"
      "macchiato"
      "mocha"
      "frappe"
    ];
    supports = [
      "light"
      "dark"
    ];
    appearanceMapping = {
      light = "latte";
      dark = "macchiato";
    };
    author = "Catppuccin";
    homepage = "https://github.com/catppuccin/catppuccin";
  };

  gruvbox = {
    name = "Gruvbox Material";
    id = "gruvbox";
    variants = [
      "dark"
      "light"
    ];
    supports = [
      "dark"
      "light"
    ];
    appearanceMapping = {
      light = "light";
      dark = "dark";
    };
    author = "sainnhe";
    homepage = "https://github.com/sainnhe/gruvbox-material";
  };

  kanagawa = {
    name = "Kanagawa";
    id = "kanagawa";
    variants = [
      "wave"
      "dragon"
      "lotus"
    ];
    supports = [
      "light"
      "dark"
    ];
    appearanceMapping = {
      light = "lotus";
      dark = "wave";
    };
    author = "rebelot";
    homepage = "https://github.com/rebelot/kanagawa.nvim";
  };

  rose-pine = {
    name = "Rosé Pine";
    id = "rose-pine";
    variants = [
      "dawn"
      "moon"
      "main"
    ];
    supports = [
      "light"
      "dark"
    ];
    appearanceMapping = {
      light = "dawn";
      dark = "moon";
    };
    author = "Rosé Pine";
    homepage = "https://github.com/rose-pine/rose-pine";
  };

  solarized = {
    name = "Solarized";
    id = "solarized";
    variants = [
      "dark"
      "light"
    ];
    supports = [
      "dark"
      "light"
    ];
    appearanceMapping = {
      light = "light";
      dark = "dark";
    };
    author = "Ethan Schoonover";
    homepage = "https://ethanschoonover.com/solarized/";
  };

  nord = {
    name = "Nord";
    id = "nord";
    variants = [
      "default"
      "light"
    ];
    supports = [
      "dark"
      "light"
    ];
    appearanceMapping = {
      light = "light";
      dark = "default";
    };
    author = "Arctic Ice Studio";
    homepage = "https://www.nordtheme.com/";
  };

  everforest = {
    name = "Everforest";
    id = "everforest";
    variants = [
      "dark-soft"
      "dark-medium"
      "dark-hard"
      "light-soft"
      "light-medium"
      "light-hard"
    ];
    supports = [
      "dark"
      "light"
    ];
    appearanceMapping = {
      light = "light-medium";
      dark = "dark-medium";
    };
    author = "sainnhe";
    homepage = "https://github.com/sainnhe/everforest";
  };

  black-metal = {
    name = "Black Metal";
    id = "black-metal";
    variants = [
      "nile"
      "gorgoroth"
      "morbid"
    ];
    supports = [ "dark" ];
    appearanceMapping = {
      dark = "gorgoroth";
    };
    author = "metalelf0";
    homepage = "https://github.com/metalelf0/base16-black-metal-scheme";
  };

  tokyonight = {
    name = "Tokyonight";
    id = "tokyonight";
    variants = [
      "night"
      "storm"
      "day"
    ];
    supports = [
      "dark"
      "light"
    ];
    appearanceMapping = {
      light = "day";
      dark = "night";
    };
    author = "folke";
    homepage = "https://github.com/folke/tokyonight.nvim";
  };

  monokai = {
    name = "Monokai";
    id = "monokai";
    variants = [ "default" ];
    supports = [ "dark" ];
    appearanceMapping = {
      dark = "default";
    };
    author = "Wimer Hazenberg";
    homepage = "https://monokai.pro/";
  };

  flexoki = {
    name = "Flexoki";
    id = "flexoki";
    variants = [
      "dark"
      "light"
    ];
    supports = [
      "light"
      "dark"
    ];
    appearanceMapping = {
      light = "light";
      dark = "dark";
    };
    author = "Steph Ango (kepano)";
    homepage = "https://github.com/kepano/flexoki";
  };

  kanso = {
    name = "Kanso";
    id = "kanso";
    variants = [
      "zen"
      "ink"
      "mist"
      "pearl"
    ];
    supports = [
      "light"
      "dark"
    ];
    appearanceMapping = {
      light = "pearl";
      dark = "ink";
    };
    author = "webhooked";
    homepage = "https://github.com/webhooked/kanso.nvim";
  };

  retroism = {
    name = "Retroism";
    id = "retroism";
    variants = [
      "dark"
      "amber"
      "green"
    ];
    supports = [ "dark" ];
    appearanceMapping = {
      dark = "dark";
    };
    author = "diinki";
    homepage = "https://github.com/diinki/linux-retroism";
  };

  apple-system-colors = {
    name = "Apple System Colors";
    id = "apple-system-colors";
    variants = [ "light" ];
    supports = [ "light" ];
    appearanceMapping = {
      light = "light";
    };
    author = "Apple Inc.";
    homepage = "https://developer.apple.com/design/human-interface-guidelines/color";
  };
}
