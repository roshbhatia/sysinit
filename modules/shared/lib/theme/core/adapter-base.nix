{
  lib,
}:

with lib;

{
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
      config = configBuilder themeData.semanticColors colorMapping;

      configWithTransparency =
        if transparent then
          applyTransparency {
            inherit config;
            transparency = transparencyConfig;
            applyFn = configBuilder.applyTransparency or (c: _t: c);
          }
        else
          config;

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
        inherit theme;
        inherit config;
        exportedAt = toString (builtins.floor (now / 1000));
      };
    in
    builtins.toJSON exported;

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

  mergeAdapterConfig = baseConfig: overrides: recursiveUpdate baseConfig overrides;

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

  createColorGetter =
    semanticColors: defaultColor: colorName:
    semanticColors.${colorName} or defaultColor;
}
