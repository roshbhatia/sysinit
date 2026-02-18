{
  ...
}:
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
}
