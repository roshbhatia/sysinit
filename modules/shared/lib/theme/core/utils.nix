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

  hexDigitValue =
    c:
    if c == "0" then 0
    else if c == "1" then 1
    else if c == "2" then 2
    else if c == "3" then 3
    else if c == "4" then 4
    else if c == "5" then 5
    else if c == "6" then 6
    else if c == "7" then 7
    else if c == "8" then 8
    else if c == "9" then 9
    else if c == "a" then 10
    else if c == "b" then 11
    else if c == "c" then 12
    else if c == "d" then 13
    else if c == "e" then 14
    else if c == "f" then 15
    else 0;

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
        in
        (hexDigitValue (elemAt chars 0) * 16) + (hexDigitValue (elemAt chars 1));
    in
    {
      r = hexToInt r;
      g = hexToInt g;
      b = hexToInt b;
    };

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

  blendColor =
    baseColor: overlayColor: alpha:
    let
      base = hexToRgb baseColor;
      overlay = hexToRgb overlayColor;
      clamp =
        v:
        if v < 0 then
          0
        else if v > 255 then
          255
        else
          v;
      alphaInt = builtins.floor (alpha * 100);
      blendChannel = b: o: clamp (builtins.floor (((alphaInt * o) + ((100 - alphaInt) * b)) / 100));
    in
    rgbToHex {
      r = blendChannel base.r overlay.r;
      g = blendChannel base.g overlay.g;
      b = blendChannel base.b overlay.b;
    };

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

  createSemanticMapping = palette:
    let
      get = name: fallback: safeGetColor palette name fallback;
      getOr = name: fallback: get name fallback;
    in
    {
      background = {
        primary = palette.base;
        secondary = palette.surface;
        tertiary = getOr "surface_alt" palette.surface;
        overlay = getOr "overlay" palette.surface;
      };

      foreground = {
        primary = palette.text;
        secondary = getOr "subtext1" palette.text;
        muted = getOr "subtext0" palette.text;
        subtle = getOr "subtle" (getOr "overlay" palette.surface);
      };

      accent = {
        primary = palette.accent;
        secondary = getOr "accent_secondary" palette.accent;
        tertiary = getOr "accent_tertiary" palette.accent;
        quaternary = getOr "accent_quaternary" palette.accent;
        dim = getOr "accent_dim" (getOr "overlay" palette.surface);
      };

      semantic = {
        success = getOr "green_vibrant" palette.green;
        warning = getOr "yellow_vibrant" palette.yellow;
        error = getOr "red_vibrant" palette.red;
        info = getOr "blue_vibrant" palette.blue;
      };

      syntax = {
        keyword = getOr "mauve" palette.blue;
        string = palette.green;
        number = getOr "peach" palette.orange;
        comment = getOr "comment" (getOr "overlay" palette.surface);
        function = palette.blue;
        variable = palette.text;
        type = palette.yellow;
        operator = getOr "sky" palette.cyan;
        constant = getOr "peach" palette.orange;
        builtin = palette.red;
      };

      ui = {
        cursor = getOr "cursor_grey" palette.accent;
        cursor_line = getOr "cursor_line_highlight" (
          blendColor palette.base (getOr "foam" palette.green) 0.15
        );
        visual_selection = getOr "highlight_high" palette.surface;
        match_paren = palette.accent;
        line_number = getOr "comment" (getOr "overlay" palette.surface);
        line_number_active = getOr "line_number_active" palette.accent;
      };

      diff =
        let
          inherit (palette) base;
          green = getOr "green_vibrant" palette.green;
          yellow = getOr "yellow_vibrant" palette.yellow;
          red = getOr "red_vibrant" palette.red;
          blue = getOr "blue_vibrant" palette.blue;
        in
        {
          add = green;
          add_bg = blendColor base green 0.20;
          change = yellow;
          change_bg = blendColor base yellow 0.20;
          delete = red;
          delete_bg = blendColor base red 0.20;
          text = blue;
        };

      plugins =
        let
          inherit (palette) base;
          inherit (palette) surface;
          inherit (palette) text;
          inherit (palette) accent;
          muted = getOr "comment" (getOr "overlay" palette.surface);
        in
        {
          telescope = {
            border = accent;
            selection_bg = blendColor base accent 0.2;
            selection_fg = text;
            title = getOr "magenta" palette.accent;
          };

          filetree = {
            border = muted;
            separator = muted;
            title = accent;
          };

          completion = {
            border = accent;
            menu_bg = surface;
            selection_bg = blendColor base accent 0.25;
            selection_fg = accent;
          };

          search = {
            match_bg = palette.yellow;
            match_fg = base;
            incremental_bg = getOr "orange" palette.yellow;
            incremental_fg = base;
          };

          window = {
            border = accent;
            separator = muted;
            statusline_active = text;
            statusline_inactive = muted;
            winbar_active = text;
            winbar_inactive = muted;
            float_border = accent;
            float_title = getOr "magenta" palette.accent;
          };
        };

      extended = removeAttrs palette [
      "base"
      "surface"
      "surface_alt"
      "overlay"
      "text"
      "accent"
      "red"
      "green"
      "yellow"
      "blue"
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
      overrides =
        (if hasAttr "overrides" base then base.overrides else { })
        // (if hasAttr "overrides" override then override.overrides else { });
    };
}
