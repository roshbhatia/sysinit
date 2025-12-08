{
  lib,
}:

with lib;

{
  /*
    Create Bat theme configuration.

    Bat is a cat clone with syntax highlighting. This adapter generates theme
    configurations dynamically from semantic colors, mapping them to bat's
    color requirements.

    Bat supports TextMate (.tmTheme) format, but we can also generate simpler
    configs that reference theme names known to bat's internal themes.
  */

  createBatTheme =
    theme: validatedConfig:
    let
      palette = theme.palettes.${validatedConfig.variant};
      semanticColors = theme.semanticMapping palette;

      # Map theme names to bat's native theme names
      nativeThemeMap = {
        "catppuccin-frappe" = "Catppuccin Frappe";
        "catppuccin-latte" = "Catppuccin Latte";
        "catppuccin-macchiato" = "Catppuccin Macchiato";
        "catppuccin-mocha" = "Catppuccin Mocha";
        "gruvbox-dark" = "gruvbox-dark";
        "gruvbox-light" = "gruvbox-light";
        "nord-dark" = "Nord";
        "solarized-dark" = "Solarized (dark)";
        "solarized-light" = "Solarized (light)";
      };

      themeKey = "${validatedConfig.colorscheme}-${validatedConfig.variant}";
      hasNativeTheme = hasAttr themeKey nativeThemeMap;

      # Determine which bat theme to use
      batThemeName =
        if hasNativeTheme then
          nativeThemeMap.${themeKey}
        else if hasAttr "bat" theme.appAdapters then
          if isFunction theme.appAdapters.bat then
            theme.appAdapters.bat validatedConfig.variant
          else if isAttrs theme.appAdapters.bat then
            if hasAttr validatedConfig.variant theme.appAdapters.bat then
              theme.appAdapters.bat.${validatedConfig.variant}
            else
              themeKey
          else
            theme.appAdapters.bat
        else
          themeKey;

      # Helper to convert color to RGB format for tmTheme
      hexToRgb =
        hex:
        let
          cleaned = lib.removePrefix "#" hex;
          r = builtins.substring 0 2 cleaned;
          g = builtins.substring 2 2 cleaned;
          b = builtins.substring 4 2 cleaned;
        in
        "#${lib.toUpper r}${lib.toUpper g}${lib.toUpper b}";

      # Generate TextMate theme XML for bat
      generateTmTheme = ''
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
          <key>name</key>
          <string>\${batThemeName}</string>
          <key>settings</key>
          <array>
            <dict>
              <key>settings</key>
              <dict>
                <key>background</key>
                <string>\${hexToRgb semanticColors.background.primary}</string>
                <key>foreground</key>
                <string>\${hexToRgb semanticColors.foreground.primary}</string>
                <key>caret</key>
                <string>\${hexToRgb semanticColors.accent.primary}</string>
                <key>lineHighlight</key>
                <string>\${hexToRgb semanticColors.background.secondary}</string>
                <key>selection</key>
                <string>\${hexToRgb semanticColors.accent.dim}</string>
              </dict>
            </dict>
            <dict>
              <key>name</key>
              <string>Comment</string>
              <key>scope</key>
              <string>comment</string>
              <key>settings</key>
              <dict>
                <key>foreground</key>
                <string>\${hexToRgb semanticColors.foreground.muted}</string>
                <key>fontStyle</key>
                <string>italic</string>
              </dict>
            </dict>
            <dict>
              <key>name</key>
              <string>String</string>
              <key>scope</key>
              <string>string</string>
              <key>settings</key>
              <dict>
                <key>foreground</key>
                <string>\${hexToRgb semanticColors.syntax.string}</string>
              </dict>
            </dict>
            <dict>
              <key>name</key>
              <string>Number</string>
              <key>scope</key>
              <string>constant.numeric</string>
              <key>settings</key>
              <dict>
                <key>foreground</key>
                <string>\${hexToRgb semanticColors.semantic.warning}</string>
              </dict>
            </dict>
            <dict>
              <key>name</key>
              <string>Keyword</string>
              <key>scope</key>
              <string>keyword, storage</string>
              <key>settings</key>
              <dict>
                <key>foreground</key>
                <string>\${hexToRgb semanticColors.syntax.keyword}</string>
              </dict>
            </dict>
            <dict>
              <key>name</key>
              <string>Operator</string>
              <key>scope</key>
              <string>keyword.operator</string>
              <key>settings</key>
              <dict>
                <key>foreground</key>
                <string>\${hexToRgb semanticColors.syntax.operator}</string>
              </dict>
            </dict>
            <dict>
              <key>name</key>
              <string>Function</string>
              <key>scope</key>
              <string>entity.name.function, support.function</string>
              <key>settings</key>
              <dict>
                <key>foreground</key>
                <string>\${hexToRgb semanticColors.syntax.function}</string>
              </dict>
            </dict>
            <dict>
              <key>name</key>
              <string>Variable</string>
              <key>scope</key>
              <string>variable</string>
              <key>settings</key>
              <dict>
                <key>foreground</key>
                <string>\${hexToRgb semanticColors.foreground.primary}</string>
              </dict>
            </dict>
            <dict>
              <key>name</key>
              <string>Type</string>
              <key>scope</key>
              <string>entity.name.type, support.type, support.class</string>
              <key>settings</key>
              <dict>
                <key>foreground</key>
                <string>\${hexToRgb semanticColors.syntax.type}</string>
              </dict>
            </dict>
            <dict>
              <key>name</key>
              <string>Constant</string>
              <key>scope</key>
              <string>constant, support.constant</string>
              <key>settings</key>
              <dict>
                <key>foreground</key>
                <string>\${hexToRgb semanticColors.syntax.constant}</string>
              </dict>
            </dict>
            <dict>
              <key>name</key>
              <string>Punctuation</string>
              <key>scope</key>
              <string>punctuation</string>
              <key>settings</key>
              <dict>
                <key>foreground</key>
                <string>\${hexToRgb semanticColors.foreground.secondary}</string>
              </dict>
            </dict>
            <dict>
              <key>name</key>
              <string>Tag</string>
              <key>scope</key>
              <string>entity.name.tag</string>
              <key>settings</key>
              <dict>
                <key>foreground</key>
                <string>\${hexToRgb semanticColors.syntax.keyword}</string>
              </dict>
            </dict>
            <dict>
              <key>name</key>
              <string>Attribute</string>
              <key>scope</key>
              <string>entity.other.attribute-name</string>
              <key>settings</key>
              <dict>
                <key>foreground</key>
                <string>\${hexToRgb semanticColors.syntax.function}</string>
              </dict>
            </dict>
            <dict>
              <key>name</key>
              <string>Invalid</string>
              <key>scope</key>
              <string>invalid</string>
              <key>settings</key>
              <dict>
                <key>foreground</key>
                <string>\${hexToRgb semanticColors.semantic.error}</string>
              </dict>
            </dict>
          </array>
        </dict>
        </plist>
      '';
    in
    {
      inherit batThemeName hasNativeTheme;
      tmTheme = generateTmTheme;
    };
}
