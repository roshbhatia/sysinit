{ lib }:

with lib;

{
  standardKeys = {
    background = "primary background color";
    foreground = "primary text/foreground color";
    surface = "secondary background (UI elements)";
    overlay = "tertiary background (floating elements)";

    text_primary = "main text color";
    text_secondary = "secondary text";
    text_muted = "muted/dim text";

    accent = "primary accent color";
    accent_secondary = "secondary accent";
    accent_dim = "dimmed accent";

    success = "success semantic color";
    warning = "warning semantic color";
    error = "error semantic color";
    info = "info semantic color";

    highlight_low = "low emphasis highlight";
    highlight_mid = "medium emphasis highlight";
    highlight_high = "high emphasis highlight";
  };

  conversionMaps = {
    catppuccin_macchiato = {
      base = "background";
      text = "text_primary";
      subtext0 = "text_secondary";
      subtext1 = "text_muted";
      surface0 = "surface";
      overlay0 = "overlay";
      mauve = "accent";
      sapphire = "accent_secondary";
      surface1 = "accent_dim";
    };

    gruvbox_dark = {
      bg0 = "background";
      fg1 = "text_primary";
      fg2 = "text_secondary";
      fg4 = "text_muted";
      bg1 = "surface";
      bg2 = "overlay";
      blue = "accent";
      purple = "accent_secondary";
      gray = "accent_dim";
    };

    gruvbox_light = {
      bg0 = "background";
      fg0 = "text_primary";
      fg1 = "text_secondary";
      fg4 = "text_muted";
      bg1 = "surface";
      bg2 = "overlay";
      blue = "accent";
      purple = "accent_secondary";
      gray = "accent_dim";
    };

    rose_pine_dawn = {
      base = "background";
      text = "text_primary";
      subtle = "text_secondary";
      muted = "text_muted";
      surface = "surface";
      overlay = "overlay";
      love = "accent";
      rose = "accent_secondary";
      iris = "accent_dim";
    };

    rose_pine_main = {
      base = "background";
      text = "text_primary";
      subtle = "text_secondary";
      muted = "text_muted";
      surface = "surface";
      overlay = "overlay";
      love = "accent";
      rose = "accent_secondary";
      iris = "accent_dim";
    };

    rose_pine_moon = {
      base = "background";
      text = "text_primary";
      subtle = "text_secondary";
      muted = "text_muted";
      surface = "surface";
      overlay = "overlay";
      love = "accent";
      rose = "accent_secondary";
      iris = "accent_dim";
    };

    solarized_dark = {
      base03 = "background";
      base0 = "text_primary";
      base1 = "text_secondary";
      base2 = "text_muted";
      base02 = "surface";
      base01 = "overlay";
      base09 = "accent";
      violet = "accent_secondary";
      base00 = "accent_dim";
    };

    solarized_light = {
      base3 = "background";
      base00 = "text_primary";
      base0 = "text_secondary";
      base1 = "text_muted";
      base2 = "surface";
      base02 = "overlay";
      base09 = "accent";
      violet = "accent_secondary";
      base01 = "accent_dim";
    };

    nord = {
      nord0 = "background";
      nord4 = "text_primary";
      nord5 = "text_secondary";
      nord6 = "text_muted";
      nord1 = "surface";
      nord2 = "overlay";
      nord9 = "accent";
      nord10 = "accent_secondary";
      nord3 = "accent_dim";
    };

    kanagawa_wave = {
      sumiInk0 = "background";
      fujiWhite = "text_primary";
      oldWhite = "text_secondary";
      sumiInk5 = "text_muted";
      sumiInk1 = "surface";
      sumiInk2 = "overlay";
      sakuraPink = "accent";
      waveBlue1 = "accent_secondary";
      sumiInk4 = "accent_dim";
    };

    kanagawa_dragon = {
      sumiInk0 = "background";
      fujiWhite = "text_primary";
      oldWhite = "text_secondary";
      sumiInk5 = "text_muted";
      sumiInk1 = "surface";
      sumiInk2 = "overlay";
      sakuraPink = "accent";
      dragonBlue = "accent_secondary";
      sumiInk4 = "accent_dim";
    };

    everforest_dark_soft = {
      bg0 = "background";
      fg = "text_primary";
      bg4 = "text_secondary";
      bg2 = "text_muted";
      bg1 = "surface";
      bg3 = "overlay";
      green = "accent";
      blue = "accent_secondary";
      bg5 = "accent_dim";
    };

    everforest_dark_medium = {
      bg0 = "background";
      fg = "text_primary";
      bg4 = "text_secondary";
      bg2 = "text_muted";
      bg1 = "surface";
      bg3 = "overlay";
      green = "accent";
      blue = "accent_secondary";
      bg5 = "accent_dim";
    };

    everforest_dark_hard = {
      bg0 = "background";
      fg = "text_primary";
      bg4 = "text_secondary";
      bg2 = "text_muted";
      bg1 = "surface";
      bg3 = "overlay";
      green = "accent";
      blue = "accent_secondary";
      bg5 = "accent_dim";
    };

    everforest_light_soft = {
      bg0 = "background";
      fg = "text_primary";
      bg4 = "text_secondary";
      bg2 = "text_muted";
      bg1 = "surface";
      bg3 = "overlay";
      green = "accent";
      blue = "accent_secondary";
      bg5 = "accent_dim";
    };

    everforest_light_medium = {
      bg0 = "background";
      fg = "text_primary";
      bg4 = "text_secondary";
      bg2 = "text_muted";
      bg1 = "surface";
      bg3 = "overlay";
      green = "accent";
      blue = "accent_secondary";
      bg5 = "accent_dim";
    };

    everforest_light_hard = {
      bg0 = "background";
      fg = "text_primary";
      bg4 = "text_secondary";
      bg2 = "text_muted";
      bg1 = "surface";
      bg3 = "overlay";
      green = "accent";
      blue = "accent_secondary";
      bg5 = "accent_dim";
    };

    black_metal_nile = {
      bg = "background";
      fg = "text_primary";
      bg1 = "text_secondary";
      comment = "text_muted";
      bg2 = "surface";
      bg3 = "overlay";
      red = "accent";
      blue = "accent_secondary";
      bg4 = "accent_dim";
    };

    black_metal_gorgoroth = {
      bg = "background";
      fg = "text_primary";
      bg1 = "text_secondary";
      comment = "text_muted";
      bg2 = "surface";
      bg3 = "overlay";
      red = "accent";
      blue = "accent_secondary";
      bg4 = "accent_dim";
    };

    black_metal_morbid = {
      bg = "background";
      fg = "text_primary";
      bg1 = "text_secondary";
      comment = "text_muted";
      bg2 = "surface";
      bg3 = "overlay";
      red = "accent";
      blue = "accent_secondary";
      bg4 = "accent_dim";
    };
  };

  normalizePalette =
    paletteId: originalPalette:
    let
      normalized = mapAttrs (
        standardKey: _:
        originalPalette.${(attrByPath [ paletteId standardKey ] null conversionMaps)} or throw
          "Required color for standard key '${standardKey}' not found in palette '${paletteId}'"
      ) standardKeys;

      extended = filterAttrs (key: _: !(hasAttr key normalized)) originalPalette;
    in
    normalized // extended;

  normalizePaletteSimple =
    paletteId: originalPalette:
    let
      conversion =
        conversionMaps.${paletteId} or (throw "No conversion map defined for palette: ${paletteId}");

      # Reverse the map: standard_key -> original_key
      reverseMap = foldl' (
        acc: originalKey:
        let
          standardKey = conversion.${originalKey};
        in
        acc // { "${standardKey}" = originalPalette.${originalKey}; }
      ) { } (attrNames conversion);

      # Verify all standard keys are mapped
      missingKeys = filterAttrs (key: _: !(hasAttr key reverseMap)) standardKeys;
    in
    if missingKeys != { } then
      throw "Palette '${paletteId}' missing conversions for keys: ${concatStringsSep ", " (attrNames missingKeys)}"
    else
      reverseMap // originalPalette;

  getConversionMap =
    paletteId:
    conversionMaps.${paletteId} or (throw "No conversion map defined for palette: ${paletteId}");

  validateNormalizedPalette =
    normalizedPalette:
    let
      missingKeys = filterAttrs (requiredKey: _: !(hasAttr requiredKey normalizedPalette)) standardKeys;
    in
    if missingKeys != { } then
      throw "Normalized palette missing required keys: ${concatStringsSep ", " (attrNames missingKeys)}"
    else
      true;
}
