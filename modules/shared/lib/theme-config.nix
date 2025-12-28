# Utilities for consistent theme handling across applications
{ lib }:

let
  themes = import ./theme { inherit lib; };
in
{
  # Get the complete theme palette for a given colorscheme and variant
  getThemePalette = colorscheme: variant: themes.getThemePalette colorscheme variant;

  # Generate app-specific theme JSON configuration
  # Used by neovim, k9s, and other theme-aware apps
  generateAppJSON = app: theme: themes.generateAppJSON app theme;

  # Extract common theme values for use in configs
  # Returns an attribute set with font, transparency, and appearance
  extractThemeValues = theme: {
    inherit (theme) font transparency appearance;
  };

  # Create a striped hex color (remove # prefix)
  stripHashColor = lib.removePrefix "#";
}
