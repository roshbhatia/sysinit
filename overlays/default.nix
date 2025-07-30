# overlays/default.nix
# Purpose: Aggregates all overlays for the system configuration
# This file collects and applies all package overlays

{
  inputs,
  system,
  ...
}:

[
  # Custom package overlays
  (import ./packages.nix { inherit inputs system; })

  # Nushell plugin overlays
  (import ./nushell-plugins.nix { inherit inputs system; })
]
