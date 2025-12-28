# Helper functions for generating application configuration files
{ lib }:

{
  # Generate a JSON file with theme-aware defaults
  # Includes font, transparency, and colorscheme from values.theme
  makeThemeJsonConfig =
    values: overrides:
    lib.recursiveUpdate {
      font = {
        inherit (values.theme.font) monospace symbols;
      };
      transparency = {
        inherit (values.theme.transparency) opacity blur;
      };
    } overrides;

  # Wrap a Nix value as JSON for use in xdg.configFile
  toJsonFile = builtins.toJSON;
}
