{ lib, ... }:

with lib;

rec {
  isValidHexColor =
    color:
    let

      cleaned = removePrefix "#" color;

      isValidLength = (stringLength cleaned == 3) || (stringLength cleaned == 6);

      isHex = all (
        c:
        elem c [
          "0"
          "1"
          "2"
          "3"
          "4"
          "5"
          "6"
          "7"
          "8"
          "9"
          "a"
          "b"
          "c"
          "d"
          "e"
          "f"
          "A"
          "B"
          "C"
          "D"
          "E"
          "F"
        ]
      ) (stringToCharacters cleaned);
    in
    isValidLength && isHex;

  normalizeHexColor = color: if hasPrefix "#" color then color else "#${color}";

  expandHexColor =
    color:
    let
      cleaned = removePrefix "#" color;
    in
    if stringLength cleaned == 3 then
      let
        chars = stringToCharacters cleaned;
      in
      "#${elemAt chars 0}${elemAt chars 0}${elemAt chars 1}${elemAt chars 1}${elemAt chars 2}${elemAt chars 2}"
    else
      normalizeHexColor color;

  validatePalette =
    palette:
    let
      invalidColors = filter (color: !isValidHexColor color) (attrValues palette);
    in
    if length invalidColors > 0 then
      throw "Invalid hex colors found in palette: ${concatStringsSep ", " invalidColors}"
    else
      mapAttrs (_: normalizeHexColor) palette;

  mergePalettes =
    base: override:
    let
      validatedBase = validatePalette base;
      validatedOverride = validatePalette override;
    in
    validatedBase // validatedOverride;

  safeGetColor =
    palette: colorName: fallback:
    palette.${colorName} or fallback;

  createSemanticMapping = palette: {
    background = {
      primary = safeGetColor palette "base" (safeGetColor palette "bg" "#000000");
      secondary = safeGetColor palette "surface" (safeGetColor palette "bg_alt" "#111111");
      tertiary = safeGetColor palette "surface_alt" (safeGetColor palette "bg1" "#222222");
      overlay = safeGetColor palette "overlay" (safeGetColor palette "surface0" "#333333");
    };

    foreground = {
      primary = safeGetColor palette "text" (safeGetColor palette "fg" "#ffffff");
      secondary = safeGetColor palette "subtext1" (safeGetColor palette "fg_alt" "#cccccc");
      muted = safeGetColor palette "subtext0" (safeGetColor palette "comment" "#888888");
      subtle = safeGetColor palette "overlay1" (safeGetColor palette "subtle" "#aaaaaa");
    };

    accent = {
      primary = safeGetColor palette "accent" (safeGetColor palette "blue" "#0080ff");
      secondary = safeGetColor palette "accent_secondary" (safeGetColor palette "cyan" "#00ffff");
      dim = safeGetColor palette "accent_dim" (safeGetColor palette "surface" "#333333");
    };

    semantic = {
      success = safeGetColor palette "green" "#00ff00";
      warning = safeGetColor palette "yellow" "#ffff00";
      error = safeGetColor palette "red" "#ff0000";
      info = safeGetColor palette "blue" "#0000ff";
    };

    syntax = {
      keyword = safeGetColor palette "mauve" (safeGetColor palette "purple" "#800080");
      string = safeGetColor palette "green" "#00ff00";
      number = safeGetColor palette "peach" (safeGetColor palette "orange" "#ff8000");
      comment = safeGetColor palette "overlay1" (safeGetColor palette "comment" "#888888");
      function = safeGetColor palette "blue" "#0000ff";
      variable = safeGetColor palette "text" (safeGetColor palette "fg" "#ffffff");
      type = safeGetColor palette "yellow" "#ffff00";
      operator = safeGetColor palette "sky" (safeGetColor palette "cyan" "#00ffff");
      constant = safeGetColor palette "peach" (safeGetColor palette "orange" "#ff8000");
      builtin = safeGetColor palette "red" "#ff0000";
    };

    extended = removeAttrs palette [
      "base"
      "bg"
      "surface"
      "text"
      "fg"
      "accent"
      "red"
      "green"
      "yellow"
      "blue"
      "purple"
      "orange"
      "cyan"
      "comment"
      "overlay1"
      "subtext1"
    ];
  };

  generateAnsiMappings = semanticColors: {

    "0" = semanticColors.background.primary;
    "1" = semanticColors.semantic.error;
    "2" = semanticColors.semantic.success;
    "3" = semanticColors.semantic.warning;
    "4" = semanticColors.semantic.info;
    "5" = semanticColors.syntax.keyword;
    "6" = semanticColors.syntax.operator;
    "7" = semanticColors.foreground.primary;
    "8" = semanticColors.foreground.muted;
    "9" = semanticColors.semantic.error;
    "10" = semanticColors.semantic.success;
    "11" = semanticColors.semantic.warning;
    "12" = semanticColors.semantic.info;
    "13" = semanticColors.syntax.keyword;
    "14" = semanticColors.syntax.operator;
    "15" = semanticColors.foreground.primary;
  };

  applyTransparencyPreset =
    config: presetName: presets:
    if hasAttr presetName presets then config // { transparency = presets.${presetName}; } else config;

  capitalizeFirst =
    str:
    let
      firstChar = substring 0 1 str;
      rest = substring 1 (-1) str;
    in
    (toUpper firstChar) + rest;

  mergeThemeConfigs =
    base: override:
    let
      mergeTransparency = baseT: overrideT: if overrideT == { } then baseT else baseT // overrideT;
    in
    base
    // override
    // {
      transparency = mergeTransparency (if hasAttr "transparency" base then base.transparency else { }) (
        if hasAttr "transparency" override then override.transparency else { }
      );
      presets = unique (
        (if hasAttr "presets" base then base.presets else [ ])
        ++ (if hasAttr "presets" override then override.presets else [ ])
      );
      overrides =
        (if hasAttr "overrides" base then base.overrides else { })
        // (if hasAttr "overrides" override then override.overrides else { });
    };
}
