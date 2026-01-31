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

  # Legacy functions removed - palette validation now handled by base16 YAML schemas
  safeGetColor =
    palette: colorName: fallback:
    palette.${colorName} or fallback;

  hexDigitValue =
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

  # Semantic mapping and ANSI generation removed - now handled by stylix base16 system

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
