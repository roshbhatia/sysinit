{
  utils,
  ...
}:

{
  generateNeovimJSON =
    themeData: config:
    let
      palette = themeData.palettes.${config.variant};
      semanticColors = utils.createSemanticMapping palette;
    in
    {
      inherit (config)
        colorscheme
        variant
        appearance
        font
        transparency
        ;
      inherit palette;
      semanticColors = semanticColors // {
        extended = palette;
      };
      ansi = utils.generateAnsiMappings semanticColors;
    };
}
