{
  lib,
  utils,
  ...
}:

with lib;

let
  themeNames = import ./theme-names.nix { inherit lib; };

  escapeString = s: "\"${lib.escape [ ''"'' "\\" ''\$'' ] s}\"";

  luaTable =
    attrs:
    let
      needsQuoting = k: builtins.match "[a-zA-Z_][a-zA-Z0-9_]*" k == null;
      formatKey = k: if needsQuoting k then "[\"${k}\"]" else k;
      entries = mapAttrsToList (
        k: v:
        let
          formattedKey = formatKey k;
        in
        if isString v then
          "${formattedKey} = ${escapeString v}"
        else if isAttrs v then
          "${formattedKey} = ${luaTable v}"
        else
          "${formattedKey} = ${toString v}"
      ) attrs;
    in
    "{ ${concatStringsSep ", " entries} }";
in

{
  createNeovimConfig =
    themeData: config: overrides:
    let
      pluginInfo = themeNames.getNeovimMetadata themeData.meta.id config.variant;

      baseConfig = {
        inherit (pluginInfo)
          plugin
          name
          setup
          colorscheme
          ;

        config = {
          transparent = true;
          terminal_colors = true;
          styles = {
            comments = {
              italic = true;
            };
            keywords = {
              bold = true;
            };
            functions = {
              bold = true;
            };
            strings = {
              italic = true;
            };
            variables = { };
            numbers = {
              bold = true;
            };
            booleans = {
              bold = true;
              italic = true;
            };
            properties = {
              italic = true;
            };
            types = {
              bold = true;
            };
            operators = {
              bold = true;
            };
          };
        };
      };
    in
    utils.mergeThemeConfigs baseConfig overrides;

  generateNeovimJSON =
    themeData: config:
    let
      palette = themeData.palettes.${config.variant};
      semanticColors = utils.createSemanticMapping palette;
    in
    {
      inherit (config) colorscheme variant;
      transparency = config.transparency or (throw "Missing transparency configuration");
      inherit semanticColors;
    };

  generateThemeLuaMap =
    allThemes:
    let
      buildMetadata =
        themeId: themeData:
        let
          inherit (themeData.meta) variants;
          variantEntries = listToAttrs (
            map (
              variant:
              let
                meta = themeNames.getNeovimMetadata themeId variant;
              in
              nameValuePair variant meta
            ) variants
          );
        in
        nameValuePair themeId variantEntries;

      themeMap = listToAttrs (mapAttrsToList buildMetadata allThemes);
    in
    "local THEME_CONFIG_MAP = " + luaTable themeMap + "\n\nreturn THEME_CONFIG_MAP\n";
}
