{
  lib,
}:

with lib;

{
  /*
    Unified adapter creation pattern to reduce duplication across app adapters.

    Each adapter (neovim, wezterm, firefox) follows the same pattern:
    1. Get theme data (palette, semantic colors)
    2. Define color mapping (semantic colors → app-specific colors)
    3. Build app-specific config from mapped colors
    4. Optionally export to JSON format

    This module provides the common scaffolding to reduce boilerplate from ~100 LOC
    per adapter to ~30-40 LOC by extracting the pattern.
  */

  /*
    Create an adapter configuration.

    Arguments:
      appName: string - Name of the application (e.g. "neovim")
      themeData: attrs - Theme data including semanticColors, palette, etc.
      colorMapping: attrs - Maps semantic color names to app-specific color variables
                            e.g. { "text.primary" = "foreground"; }
      configBuilder: function - Builds app config from semantic colors and mapping
                                Signature: (semanticColors, colorMapping) → config
      jsonBuilder: function - Optional builder for JSON export
                              Signature: (config, appName) → string (JSON)
      transparent: bool - Whether to apply transparency effects (default: false)
      transparencyConfig: attrs - Transparency settings (opacity, blur) if transparent=true

    Returns:
      {
        config: attrs - The application configuration
        json: string - JSON export (if jsonBuilder provided)
        appName: string - Name of the app
        metadata: attrs - Generated metadata
      }
  */
  createAdapter =
    {
      appName,
      themeData,
      colorMapping,
      configBuilder,
      jsonBuilder ? null,
      transparent ? false,
      transparencyConfig ? { },
    }:
    let
      # Build the main configuration
      config = configBuilder themeData.semanticColors colorMapping;

      # Apply transparency if requested
      configWithTransparency =
        if transparent then
          applyTransparency {
            inherit config;
            transparency = transparencyConfig;
            applyFn = (configBuilder.applyTransparency or (c: _t: c));
          }
        else
          config;

      # Generate JSON if builder provided
      json = if jsonBuilder != null then jsonBuilder configWithTransparency appName else null;
    in
    {
      inherit config json appName;
      metadata = {
        generatedAt = "builtins.now";
        semanticColorsUsed = builtins.attrNames themeData.semanticColors;
        colorMappingUsed = builtins.attrNames colorMapping;
      };
    };

  /*
    Standard JSON export function for adapters.

    Arguments:
      config: attrs - The adapter configuration to export
      appName: string - Name of the application
      theme: attrs - Optional theme metadata

    Returns:
      string - JSON representation
  */
  standardJsonExport =
    {
      config,
      appName,
      theme ? { },
    }:
    let
      exported = {
        app = appName;
        version = "1.0";
        type = "theme-config";
        theme = theme;
        config = config;
        exportedAt = builtins.toString (builtins.floor (builtins.now / 1000));
      };
    in
    builtins.toJSON exported;

  /*
    Apply transparency settings to a configuration.

    Arguments:
      config: attrs - The base configuration
      transparency: attrs - { opacity: float, blur: int }
      applyFn: function - Custom function to apply transparency
                          Signature: (config, transparency) → config

    Returns:
      attrs - Configuration with transparency applied
  */
  applyTransparency =
    {
      config,
      transparency,
      applyFn ? null,
    }:
    let
      defaultApply =
        c: _t:
        c
        // {
          inherit transparency;
        };
    in
    (if applyFn != null then applyFn else defaultApply) config transparency;

  /*
    Merge adapter configurations with overrides.

    Useful for applying user customizations to generated adapter configs.

    Arguments:
      baseConfig: attrs - Generated adapter configuration
      overrides: attrs - User overrides to merge in

    Returns:
      attrs - Merged configuration
  */
  mergeAdapterConfig = baseConfig: overrides: recursiveUpdate baseConfig overrides;

  /*
    Validate adapter color mapping completeness.

    Ensures all required semantic colors are mapped.

    Arguments:
      mapping: attrs - The color mapping to validate
      requiredColors: list - List of color names that must be in mapping

    Returns:
      bool - True if all required colors are mapped
  */
  validateColorMapping =
    mapping: requiredColors:
    let
      mappedColors = builtins.attrNames mapping;
      missing = filter (c: !elem c mappedColors) requiredColors;
    in
    if missing != [ ] then
      throw "Color mapping missing required colors: ${concatStringsSep ", " missing}"
    else
      true;

  /*
    Helper to create semantic color getter with fallbacks.

    Arguments:
      semanticColors: attrs - The semantic color palette
      defaultColor: string - Default color if not found

    Returns:
      function - (colorName) → color string
  */
  createColorGetter =
    semanticColors: defaultColor: colorName:
    semanticColors.${colorName} or defaultColor;
}
