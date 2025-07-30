# overlays/packages.nix
# Purpose: General package overlays for custom packages and overrides
# This overlay adds or modifies packages in nixpkgs

{
  ...
}:

_final: _prev: {
  # Custom package overrides can be added here
  # Example:
  # customPackage = prev.somePackage.overrideAttrs (oldAttrs: {
  #   version = "custom-version";
  #   # ... other overrides
  # });
}
