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

  # Convert hex color to RGB components (0-255)
  hexToRgb =
    color:
    let
      expanded = expandHexColor color;
      cleaned = removePrefix "#" expanded;
      r = substring 0 2 cleaned;
      g = substring 2 2 cleaned;
      b = substring 4 2 cleaned;
      hexToInt =
        hex:
        let
          chars = stringToCharacters (toLower hex);
          hexDigit =
            c:
            if c == "0" then
              0
            else if c == "1" then
              1
            else if c == "2" then
              2
            else if c == "3" then
              3
            else if c == "4" then
              4
            else if c == "5" then
              5
            else if c == "6" then
              6
            else if c == "7" then
              7
            else if c == "8" then
              8
            else if c == "9" then
              9
            else if c == "a" then
              10
            else if c == "b" then
              11
            else if c == "c" then
              12
            else if c == "d" then
              13
            else if c == "e" then
              14
            else if c == "f" then
              15
            else
              0;
        in
        (hexDigit (elemAt chars 0) * 16) + (hexDigit (elemAt chars 1));
    in
    {
      r = hexToInt r;
      g = hexToInt g;
      b = hexToInt b;
    };

  # Convert RGB components to hex color
  rgbToHex =
    {
      r,
      g,
      b,
    }:
    let
      intToHex =
        n:
        let
          digits = [
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
          ];
          high = n / 16;
          low = mod n 16;
        in
        "${elemAt digits high}${elemAt digits low}";
    in
    "#${intToHex r}${intToHex g}${intToHex b}";

  # Blend two colors with alpha (0.0 = base color, 1.0 = overlay color)
  # Uses alpha * overlay + (1-alpha) * base for each channel
  blendColor =
    baseColor: overlayColor: alpha:
    let
      base = hexToRgb baseColor;
      overlay = hexToRgb overlayColor;
      # Clamp value between 0 and 255
      clamp =
        v:
        if v < 0 then
          0
        else if v > 255 then
          255
        else
          v;
      # Integer alpha (0-100)
      alphaInt = builtins.floor (alpha * 100);
      blendChannel = b: o: clamp (builtins.floor (((alphaInt * o) + ((100 - alphaInt) * b)) / 100));
    in
    rgbToHex {
      r = blendChannel base.r overlay.r;
      g = blendChannel base.g overlay.g;
      b = blendChannel base.b overlay.b;
    };

  # Adjust brightness of a color by percentage (-100 to 100)
  # Positive values lighten, negative values darken
  adjustBrightness =
    color: percent:
    let
      rgb = hexToRgb color;
      clamp =
        v:
        if v < 0 then
          0
        else if v > 255 then
          255
        else
          v;
      adjust = v: clamp (builtins.floor (v * (100 + percent) / 100));
    in
    rgbToHex {
      r = adjust rgb.r;
      g = adjust rgb.g;
      b = adjust rgb.b;
    };

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
      tertiary = safeGetColor palette "accent_tertiary" (safeGetColor palette "purple" "#8000ff");
      quaternary = safeGetColor palette "accent_quaternary" (safeGetColor palette "magenta" "#ff00ff");
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

    ui = {
      cursor = safeGetColor palette "accent" (safeGetColor palette "blue" "#0080ff");
      cursor_line = blendColor (safeGetColor palette "base" (safeGetColor palette "bg" "#000000")) (
        safeGetColor
        palette
        "surface"
        (safeGetColor palette "bg_alt" "#111111")
      ) 0.5;
      visual_selection = safeGetColor palette "highlight_high" (
        safeGetColor palette "surface2" (safeGetColor palette "surface" "#333333")
      );
      match_paren = safeGetColor palette "accent" (safeGetColor palette "blue" "#0080ff");
      line_number = safeGetColor palette "comment" (safeGetColor palette "overlay1" "#888888");
      line_number_active = safeGetColor palette "accent" (
        safeGetColor palette "foam" (safeGetColor palette "cyan" "#00ffff")
      );
    };

    diff =
      let
        base = safeGetColor palette "base" (safeGetColor palette "bg" "#000000");
        green = safeGetColor palette "green" "#00ff00";
        yellow = safeGetColor palette "yellow" "#ffff00";
        red = safeGetColor palette "red" "#ff0000";
        blue = safeGetColor palette "blue" "#0000ff";
      in
      {
        add = green;
        add_bg = blendColor base green 0.15;
        change = yellow;
        change_bg = blendColor base yellow 0.15;
        delete = red;
        delete_bg = blendColor base red 0.15;
        text = blue;
      };

    # Plugin UI semantic colors
    plugins =
      let
        base = safeGetColor palette "base" (safeGetColor palette "bg" "#000000");
        surface = safeGetColor palette "surface" (safeGetColor palette "bg_alt" "#111111");
        text = safeGetColor palette "text" (safeGetColor palette "fg" "#ffffff");
        accent = safeGetColor palette "accent" (safeGetColor palette "blue" "#0080ff");
        muted = safeGetColor palette "comment" (safeGetColor palette "overlay1" "#888888");
      in
      {
        # Telescope
        telescope = {
          border = accent;
          selection_bg = blendColor base accent 0.2;
          selection_fg = text;
          title = safeGetColor palette "pink" (safeGetColor palette "magenta" "#ff00ff");
        };

        # NeoTree / File explorer
        filetree = {
          border = muted;
          separator = muted;
          title = accent;
        };

        # Completion menu
        completion = {
          border = accent;
          menu_bg = surface;
          selection_bg = blendColor base accent 0.25;
          selection_fg = accent;
        };

        # Search highlights
        search = {
          match_bg = safeGetColor palette "yellow" "#ffff00";
          match_fg = base;
          incremental_bg = safeGetColor palette "orange" (safeGetColor palette "peach" "#ff8000");
          incremental_fg = base;
        };

        # Status and window UI
        window = {
          border = accent;
          separator = muted;
          statusline_active = text;
          statusline_inactive = muted;
          winbar_active = text;
          winbar_inactive = muted;
          float_border = accent;
          float_title = safeGetColor palette "pink" (safeGetColor palette "magenta" "#ff00ff");
        };
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
