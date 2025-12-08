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

      # Helper to convert color to uppercase hex for tmTheme
      normalizeHex =
        hex:
        let
          cleaned = lib.removePrefix "#" hex;
        in
        "#${lib.toUpper cleaned}";

      # Map semantic colors to Rose Pine-style variables for comprehensive syntax highlighting
      # Based on https://github.com/rose-pine/tm-theme/blob/main/templates/template.tmTheme
      colors = {
        base = normalizeHex semanticColors.background.primary;
        surface = normalizeHex semanticColors.background.secondary;
        overlay = normalizeHex semanticColors.background.tertiary;

        muted = normalizeHex semanticColors.foreground.muted;
        subtle = normalizeHex (palette.subtle or semanticColors.foreground.secondary);
        text = normalizeHex semanticColors.foreground.primary;

        love = normalizeHex semanticColors.semantic.error;
        gold = normalizeHex semanticColors.semantic.warning;
        rose = normalizeHex (palette.rose or palette.orange or semanticColors.syntax.function);
        pine = normalizeHex (palette.pine or palette.green or semanticColors.syntax.keyword);
        foam = normalizeHex (palette.foam or palette.cyan or semanticColors.syntax.type);
        iris = normalizeHex (palette.iris or palette.purple or semanticColors.syntax.constant);

        highlightLow = normalizeHex (palette.highlight_low or semanticColors.background.secondary);
        highlightMed = normalizeHex (palette.highlight_med or semanticColors.accent.dim);
        highlightHigh = normalizeHex (palette.highlight_high or semanticColors.accent.primary);
      };

      # Generate complete TextMate theme XML following Rose Pine's structure
      generateTmTheme = ''
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
          <key>name</key>
          <string>${batThemeName}</string>
          <key>settings</key>
          <array>
            <dict>
              <key>settings</key>
              <dict>
                <key>background</key>
                <string>${colors.base}</string>
                <key>caret</key>
                <string>${colors.highlightHigh}</string>
                <key>foreground</key>
                <string>${colors.text}</string>
                <key>invisibles</key>
                <string>${colors.surface}</string>
                <key>lineHighlight</key>
                <string>${colors.highlightLow}</string>
                <key>selection</key>
                <string>${colors.highlightMed}</string>
              </dict>
            </dict>
            <dict>
              <key>name</key>
              <string>Comment</string>
              <key>scope</key>
              <string>comment</string>
              <key>settings</key>
              <dict>
                <key>fontStyle</key>
                <string>italic</string>
                <key>foreground</key>
                <string>${colors.subtle}</string>
              </dict>
            </dict>
            <dict>
              <key>name</key>
              <string>String</string>
              <key>scope</key>
              <string>string, punctuation.definition.string</string>
              <key>settings</key>
              <dict>
                <key>foreground</key>
                <string>${colors.gold}</string>
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
                <string>${colors.gold}</string>
              </dict>
            </dict>
            <dict>
              <key>name</key>
              <string>Built-in constant</string>
              <key>scope</key>
              <string>constant.language</string>
              <key>settings</key>
              <dict>
                <key>fontStyle</key>
                <string>bold</string>
                <key>foreground</key>
                <string>${colors.gold}</string>
              </dict>
            </dict>
            <dict>
              <key>name</key>
              <string>User-defined constant</string>
              <key>scope</key>
              <string>constant.character, constant.other</string>
              <key>settings</key>
              <dict>
                <key>foreground</key>
                <string>${colors.gold}</string>
              </dict>
            </dict>
            <dict>
              <key>name</key>
              <string>Variable</string>
              <key>scope</key>
              <string>variable</string>
              <key>settings</key>
              <dict>
                <key>fontStyle</key>
                <string>italic</string>
                <key>foreground</key>
                <string>${colors.text}</string>
              </dict>
            </dict>
            <dict>
              <key>name</key>
              <string>Keyword</string>
              <key>scope</key>
              <string>keyword</string>
              <key>settings</key>
              <dict>
                <key>foreground</key>
                <string>${colors.pine}</string>
              </dict>
            </dict>
            <dict>
              <key>name</key>
              <string>Storage</string>
              <key>scope</key>
              <string>storage</string>
              <key>settings</key>
              <dict>
                <key>fontStyle</key>
                <string></string>
                <key>foreground</key>
                <string>${colors.foam}</string>
              </dict>
            </dict>
            <dict>
              <key>name</key>
              <string>Storage type</string>
              <key>scope</key>
              <string>storage.type</string>
              <key>settings</key>
              <dict>
                <key>fontStyle</key>
                <string></string>
                <key>foreground</key>
                <string>${colors.foam}</string>
              </dict>
            </dict>
            <dict>
              <key>name</key>
              <string>Class name</string>
              <key>scope</key>
              <string>entity.name.class</string>
              <key>settings</key>
              <dict>
                <key>fontStyle</key>
                <string>bold</string>
                <key>foreground</key>
                <string>${colors.pine}</string>
              </dict>
            </dict>
            <dict>
              <key>name</key>
              <string>Inherited class</string>
              <key>scope</key>
              <string>entity.other.inherited-class</string>
              <key>settings</key>
              <dict>
                <key>fontStyle</key>
                <string>italic </string>
                <key>foreground</key>
                <string>${colors.pine}</string>
              </dict>
            </dict>
            <dict>
              <key>name</key>
              <string>Function name</string>
              <key>scope</key>
              <string>entity.name.function</string>
              <key>settings</key>
              <dict>
                <key>fontStyle</key>
                <string>italic</string>
                <key>foreground</key>
                <string>${colors.rose}</string>
              </dict>
            </dict>
            <dict>
              <key>name</key>
              <string>Function argument</string>
              <key>scope</key>
              <string>variable.parameter</string>
              <key>settings</key>
              <dict>
                <key>fontStyle</key>
                <string></string>
                <key>foreground</key>
                <string>${colors.iris}</string>
              </dict>
            </dict>
            <dict>
              <key>name</key>
              <string>Tag name</string>
              <key>scope</key>
              <string>entity.name.tag</string>
              <key>settings</key>
              <dict>
                <key>fontStyle</key>
                <string>bold</string>
                <key>foreground</key>
                <string>${colors.pine}</string>
              </dict>
            </dict>
            <dict>
              <key>name</key>
              <string>Tag attribute</string>
              <key>scope</key>
              <string>entity.other.attribute-name</string>
              <key>settings</key>
              <dict>
                <key>fontStyle</key>
                <string></string>
                <key>foreground</key>
                <string>${colors.iris}</string>
              </dict>
            </dict>
            <dict>
              <key>name</key>
              <string>Library function</string>
              <key>scope</key>
              <string>support.function</string>
              <key>settings</key>
              <dict>
                <key>fontStyle</key>
                <string>bold</string>
                <key>foreground</key>
                <string>${colors.rose}</string>
              </dict>
            </dict>
            <dict>
              <key>name</key>
              <string>Library constant</string>
              <key>scope</key>
              <string>support.constant</string>
              <key>settings</key>
              <dict>
                <key>fontStyle</key>
                <string>bold</string>
                <key>foreground</key>
                <string>${colors.gold}</string>
              </dict>
            </dict>
            <dict>
              <key>name</key>
              <string>Library class/type</string>
              <key>scope</key>
              <string>support.type, support.class</string>
              <key>settings</key>
              <dict>
                <key>fontStyle</key>
                <string>bold</string>
                <key>foreground</key>
                <string>${colors.foam}</string>
              </dict>
            </dict>
            <dict>
              <key>name</key>
              <string>Library variable</string>
              <key>scope</key>
              <string>support.other.variable</string>
              <key>settings</key>
              <dict>
                <key>fontStyle</key>
                <string>bold</string>
                <key>foreground</key>
                <string>${colors.love}</string>
              </dict>
            </dict>
            <dict>
              <key>name</key>
              <string>Invalid</string>
              <key>scope</key>
              <string>invalid</string>
              <key>settings</key>
              <dict>
                <key>background</key>
                <string>${colors.love}</string>
                <key>fontStyle</key>
                <string></string>
                <key>foreground</key>
                <string>${colors.text}</string>
              </dict>
            </dict>
            <dict>
              <key>name</key>
              <string>Invalid deprecated</string>
              <key>scope</key>
              <string>invalid.deprecated</string>
              <key>settings</key>
              <dict>
                <key>background</key>
                <string>${colors.iris}</string>
                <key>foreground</key>
                <string>${colors.text}</string>
              </dict>
            </dict>
            <dict>
              <key>name</key>
              <string>Punctuation, Operators</string>
              <key>scope</key>
              <string>punctuation, keyword.operator</string>
              <key>settings</key>
              <dict>
                <key>foreground</key>
                <string>${colors.subtle}</string>
              </dict>
            </dict>
          </array>
          <key>colorSpaceName</key>
          <string>sRGB</string>
          <key>semanticClass</key>
          <string>theme.${validatedConfig.appearance}.${themeKey}</string>
          <key>author</key>
          <string>Generated from ${validatedConfig.colorscheme} theme</string>
          <key>comment</key>
          <string>Dynamically generated bat theme from Nix theme system</string>
        </dict>
        </plist>
      '';
    in
    {
      inherit batThemeName hasNativeTheme;
      tmTheme = generateTmTheme;
    };
}
