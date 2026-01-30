{ lib, ... }:

let
  utils = import ../core/utils.nix { inherit lib; };
in

{
  meta = {
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

  palettes = {
    light = utils.validatePalette rec {
      # Apple system accent colors
      systemBlue = "#007AFF";
      systemBrown = "#A2845E";
      systemGray = "#8E8E93";
      systemGreen = "#28CD41";
      systemIndigo = "#5856D6";
      systemOrange = "#FF9500";
      systemPink = "#FF2D55";
      systemPurple = "#AF52DE";
      systemRed = "#FF3B30";
      systemTeal = "#55BEF0";
      systemYellow = "#FFCC00";

      # macOS light mode system grays (solid equivalents)
      labelColor = "#000000"; # Primary text
      secondaryLabelColor = "#3C3C43"; # Secondary text
      tertiaryLabelColor = "#AEAEB2"; # Tertiary text (60% opacity approx)
      quaternaryLabelColor = "#C7C7CC"; # Quaternary text (30% opacity approx)
      separatorColor = "#E5E5EA"; # Separator lines
      systemBackground = "#FFFFFF"; # Base background
      secondarySystemBackground = "#F2F2F7"; # Secondary background

      # Required theme system mappings
      base = systemBackground;
      bg = systemBackground;
      bg_alt = secondarySystemBackground;
      fg = labelColor;
      fg_alt = secondaryLabelColor;
      surface = secondarySystemBackground;
      surface_alt = separatorColor;
      overlay = separatorColor;
      teal = systemTeal;

      text = labelColor;
      subtext1 = secondaryLabelColor;
      subtext0 = tertiaryLabelColor;
      comment = systemGray;
      subtle = quaternaryLabelColor;

      # Required color mappings
      red = systemRed;
      orange = systemOrange;
      yellow = systemYellow;
      green = systemGreen;
      cyan = systemTeal;
      blue = systemBlue;
      purple = systemPurple;
      magenta = systemPink;

      # Accent system
      accent = systemBlue;
      accent_secondary = systemTeal;
      accent_tertiary = systemPurple;
      accent_dim = separatorColor;

      # UI highlights
      highlight_low = systemBackground;
      highlight_med = secondarySystemBackground;
      highlight_high = separatorColor;

      # Base16 colors for stylix
      base00 = systemBackground;
      base01 = secondarySystemBackground;
      base02 = separatorColor;
      base03 = systemGray;
      base04 = tertiaryLabelColor;
      base05 = labelColor;
      base06 = secondaryLabelColor;
      base07 = separatorColor;
      base08 = systemRed;
      base09 = systemOrange;
      base0A = systemYellow;
      base0B = systemGreen;
      base0C = systemTeal;
      base0D = systemBlue;
      base0E = systemPurple;
      base0F = systemPink;
    };
  };

  semanticMapping = palette: utils.createSemanticMapping palette;
}
