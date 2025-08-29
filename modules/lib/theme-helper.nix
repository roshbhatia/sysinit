{ lib, ... }:

with lib;

{
  mkThemedConfig =
    values: app: extraConfig:
    let
      themes = import ./theme { inherit lib; };
      appTheme = themes.getAppTheme app values.theme.colorscheme values.theme.variant;
    in
    extraConfig
    // {
      inherit themes appTheme;

      themeConfig = {
        colorscheme = values.theme.colorscheme;
        variant = values.theme.variant;
        transparency = values.theme.transparency;
      };
    };

  deployThemeFiles =
    values:
    {
      themeDir,
      targetPath,
      fileExtension ? null,
    }:
    let
      currentTheme = "${values.theme.colorscheme}-${values.theme.variant}";
      themeFileName = if fileExtension != null then "${currentTheme}.${fileExtension}" else currentTheme;
      themeFile = "${themeDir}/${themeFileName}";
    in
    optionalAttrs (pathExists themeFile) {
      "${targetPath}/${themeFileName}" = {
        source = themeFile;
        force = true;
      };
    };

  mkThemeFileConfigs =
    _values: configs:
    let
      mkThemeConfig =
        { condition, files }:
        mkIf condition (listToAttrs (map (file: nameValuePair file.name file.value) files));
    in
    mkMerge (map mkThemeConfig configs);

  mkThemeConditional =
    values: colorscheme: config:
    mkIf (values.theme.colorscheme == colorscheme) config;

  mkAllThemeFiles =
    values:
    {
      themeDir,
      targetPath,
      themes,
    }:
    let

      availableThemes = filter (theme: pathExists "${themeDir}/${theme}") themes;
      currentTheme = "${values.theme.colorscheme}-${values.theme.variant}";
    in
    if elem "${currentTheme}.toml" availableThemes then
      {
        "${targetPath}/${currentTheme}.toml" = {
          source = "${themeDir}/${currentTheme}.toml";
          force = true;
        };
      }
    else if elem "${currentTheme}.tmTheme" availableThemes then
      {
        "${targetPath}/${currentTheme}.tmTheme" = {
          source = "${themeDir}/${currentTheme}.tmTheme";
          force = true;
        };
      }
    else if elem "${currentTheme}.yaml" availableThemes then
      {
        "${targetPath}/${currentTheme}.yaml" = {
          source = "${themeDir}/${currentTheme}.yaml";
          force = true;
        };
      }
    else
      { };
}
