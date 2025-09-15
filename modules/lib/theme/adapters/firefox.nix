{ lib, ... }:

with lib;

let
  utils = import ../core/utils.nix { inherit lib; };
in

rec {
  createFirefoxConfig =
    themeData: config: overrides:
    let
      palette = themeData.palettes.${config.variant};
      semanticColors = utils.createSemanticMapping palette;
      transparency =
        if hasAttr "transparency" config then
          config.transparency
        else
          throw "Missing transparency configuration in firefox config";

      # Generate semantic CSS variables
      semanticCSSVariables = ''
        /* Semantic theme colors for Firefox */
        :root {
          /* Background colors */
          --bg-primary: ${semanticColors.background.primary};
          --bg-secondary: ${semanticColors.background.secondary};
          --bg-tertiary: ${semanticColors.background.tertiary};
          --bg-overlay: ${semanticColors.background.overlay};

          /* Text colors */
          --text-primary: ${semanticColors.foreground.primary};
          --text-secondary: ${semanticColors.foreground.secondary};
          --text-muted: ${semanticColors.foreground.muted};
          --text-subtle: ${semanticColors.foreground.subtle};

          /* Accent colors */
          --accent-primary: ${semanticColors.accent.primary};
          --accent-secondary: ${semanticColors.accent.secondary};
          --accent-tertiary: ${semanticColors.accent.tertiary or semanticColors.accent.secondary};
          --accent-dim: ${semanticColors.accent.dim};

          /* Semantic status colors */
          --color-success: ${semanticColors.semantic.success};
          --color-warning: ${semanticColors.semantic.warning};
          --color-error: ${semanticColors.semantic.error};
          --color-info: ${semanticColors.semantic.info};

          /* Syntax highlighting colors */
          --syntax-keyword: ${semanticColors.syntax.keyword};
          --syntax-string: ${semanticColors.syntax.string};
          --syntax-number: ${semanticColors.syntax.number};
          --syntax-comment: ${semanticColors.syntax.comment};
          --syntax-function: ${semanticColors.syntax.function};
          --syntax-variable: ${semanticColors.syntax.variable};
          --syntax-type: ${semanticColors.syntax.type};
          --syntax-operator: ${semanticColors.syntax.operator};
          --syntax-constant: ${semanticColors.syntax.constant};
          --syntax-builtin: ${semanticColors.syntax.builtin};

          /* Transparency and blur effects */
          --opacity: ${toString transparency.opacity};
          --blur-amount: ${toString transparency.blur}px;
        }
      '';

      # Base userContent.css with semantic colors
      baseUserContentCSS = ''
        /* Semantic theme-aware userContent.css */
        @-moz-document url-prefix(about:home), url-prefix(about:newtab) {
          body {
            background: var(--bg-primary) !important;
            color: var(--text-primary) !important;
          }

          /* Search components */
          .search-wrapper {
            background: var(--bg-secondary) !important;
            border-radius: 12px !important;
            backdrop-filter: blur(var(--blur-amount)) !important;
          }

          .search-handoff-button {
            background: var(--bg-overlay) !important;
            border: 1px solid var(--accent-secondary) !important;
            color: var(--text-primary) !important;
            border-radius: 8px !important;
            transition: all 0.2s ease !important;
          }

          .search-handoff-button:hover {
            background: var(--accent-dim) !important;
            border-color: var(--accent-primary) !important;
            transform: translateY(-1px) !important;
          }

          /* Top sites */
          .top-site-outer {
            background: var(--bg-overlay) !important;
            border-radius: 8px !important;
            backdrop-filter: blur(calc(var(--blur-amount) / 2)) !important;
            transition: all 0.2s ease !important;
          }

          .top-site-outer:hover {
            background: var(--accent-dim) !important;
            transform: translateY(-2px) !important;
            box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1) !important;
          }

          /* Menus and context elements */
          .customize-menu, .context-menu {
            background: var(--bg-secondary) !important;
            border: 1px solid var(--accent-secondary) !important;
            border-radius: 8px !important;
            backdrop-filter: blur(var(--blur-amount)) !important;
            box-shadow: 0 8px 24px rgba(0, 0, 0, 0.15) !important;
          }

          .context-menu-item:hover {
            background: var(--accent-primary) !important;
            color: var(--bg-primary) !important;
          }

          /* Customize interface elements */
          .customize-item {
            background: var(--bg-overlay) !important;
            border-radius: 6px !important;
            border: 1px solid var(--accent-dim) !important;
          }

          .customize-item:hover {
            border-color: var(--accent-tertiary) !important;
            background: var(--bg-secondary) !important;
          }

          /* Activity stream cards */
          .ds-card {
            background: var(--bg-overlay) !important;
            border: 1px solid var(--accent-dim) !important;
            border-radius: 8px !important;
          }

          .ds-card:hover {
            border-color: var(--accent-secondary) !important;
            background: var(--bg-secondary) !important;
          }
        }
      '';

      baseConfig = {
        userContentCSS = semanticCSSVariables + baseUserContentCSS;
        userChromeCSS = semanticCSSVariables;
        semanticColors = semanticColors;
        transparency = transparency;
      };

    in
    utils.mergeThemeConfigs baseConfig overrides;

  generateFirefoxJSON =
    themeData: config:
    let
      palette = themeData.palettes.${config.variant};
      semanticColors = utils.createSemanticMapping palette;
      firefoxConfig = (createFirefoxConfig themeData config { });
    in
    {
      colorscheme = themeData.meta.id;
      variant = config.variant;
      transparency =
        if hasAttr "transparency" config then
          config.transparency
        else
          throw "Missing transparency configuration in firefox config";
      inherit semanticColors palette;
      theme_identifier = "${themeData.meta.id}-${config.variant}";
    };
}
