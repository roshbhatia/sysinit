# Minimal theme library — only what Stylix can't handle itself.
# All color access should use config.lib.stylix.colors directly.
{ lib, ... }:

with lib;

let
  metadata = import ./theme/metadata.nix { inherit lib; };

  # Get base16 scheme YAML path for Stylix's base16Scheme setting
  getBase16SchemePath =
    pkgs: colorscheme: variant:
    let
      mapping = import ./theme/base16-mapping.nix { inherit pkgs; };
    in
    if hasAttr colorscheme mapping then
      if hasAttr variant mapping.${colorscheme} then
        mapping.${colorscheme}.${variant}
      else
        throw "Variant '${variant}' not found for colorscheme '${colorscheme}'. Available variants: ${
          concatStringsSep ", " (attrNames mapping.${colorscheme})
        }"
    else
      throw "Colorscheme '${colorscheme}' not found in base16 mapping. Available: ${concatStringsSep ", " (attrNames mapping)}";

  # Derive variant from appearance mode (e.g., "dark" -> "macchiato" for catppuccin)
  deriveVariantFromAppearance =
    colorscheme: appearance: currentVariant:
    let
      theme = metadata.${colorscheme} or (throw "Theme '${colorscheme}' not found");
      mapping = if appearance != null then theme.appearanceMapping.${appearance} or null else null;
      variantMatches =
        if appearance == null then true
        else if isList mapping then elem currentVariant mapping
        else if mapping != null then currentVariant == mapping
        else false;
    in
    if appearance == null then currentVariant
    else if variantMatches then currentVariant
    else if mapping == null then
      throw "Colorscheme '${colorscheme}' does not support appearance '${appearance}'"
    else if isList mapping then head mapping
    else mapping;

in
{
  inherit metadata getBase16SchemePath deriveVariantFromAppearance;
}
