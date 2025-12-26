{
  lib,
  utils,
  ...
}:

with lib;

let

  # Simple plugin metadata for neovim themes
  neovimPluginMap = {
    catppuccin = {
      plugin = "catppuccin/nvim";
      setup = "catppuccin";
    };
    gruvbox = {
      plugin = "ellisonleao/gruvbox.nvim";
      setup = "gruvbox";
    };
    solarized = {
      plugin = "craftzdog/solarized-osaka.nvim";
      setup = "solarized-osaka";
    };
    "rose-pine" = {
      plugin = "rose-pine/rose-pine.nvim";
      setup = "rose-pine";
    };
    kanagawa = {
      plugin = "rebelot/kanagawa.nvim";
      setup = "kanagawa";
    };
    nord = {
      plugin = "EdenEast/nightfox.nvim";
      setup = "nightfox";
    };
    everforest = {
      plugin = "sainnhe/everforest";
      setup = "everforest";
    };
    "black-metal" = {
      plugin = "metalelf0/black-metal-theme-neovim";
      setup = "black-metal";
    };
  };

in

{
  generateNeovimJSON =
    themeData: config:
    let
      palette = themeData.palettes.${config.variant};
      semanticColors = utils.createSemanticMapping palette;
      colorschemeId = themeData.meta.id;
      pluginInfo =
        neovimPluginMap.${colorschemeId} or {
          plugin = "${colorschemeId}/nvim";
          setup = colorschemeId;
        };
    in
    {
      inherit (config)
        colorscheme
        variant
        appearance
        font
        transparency
        ;
      inherit (pluginInfo) plugin setup;
      inherit palette;
      semanticColors = semanticColors // {
        extended = palette;
      };
      ansi = utils.generateAnsiMappings semanticColors;
    };
}
