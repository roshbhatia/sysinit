{
  lib,
  pkgs,
  system,
  ...
}:

{
  # Core utilities for system introspection and path management
  platform = import ./platform { inherit lib system; };
  paths = import ./paths { inherit lib; };
  xdg = import ./xdg { inherit lib pkgs; };

  # Configuration value schemas and validation
  values = import ./values { inherit lib; };

  # Theme system: colors, palettes, and app-specific adapters
  theme = import ./theme { inherit lib; };

  # Shell environment helpers and utilities
  shell = import ./shell { inherit lib; };

  # Package manifest management across multiple package managers
  packages = import ./packages { inherit lib pkgs system; };

  # NixOS module system utilities
  modules = import ./modules { inherit lib; };
}
