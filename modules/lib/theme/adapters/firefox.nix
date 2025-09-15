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

      baseChromeCSS = ''
        /* --------------------------------------------------------------------------------
        Translucent Firefox Theme with Semantic Colors
        Based on Fluidfox, Firefox-Mod-Blur, Atom-for-Firefox, and Brave-Fox
        --------------------------------------------------------------------------------- */

        /* Tab Shadows */
        .tabbrowser-tab:is([visuallyselected="true"],
        [multiselected]) > .tab-stack > .tab-background {
            box-shadow: 0px 0px 0px 0px rgba(0, 0, 0, 0) !important;
        }

        /* Focused Address/URL Field */
        #urlbar-background {
            outline: none !important;
            box-shadow: none !important;
        }

        /*--------- Translucency after FF 121 -----------*/

        :root #TabsToolbar,
        :root #titlebar,
        :root #tabbrowser-tabs,
        :root #PersonalToolbar,
        :root #nav-bar,
        :root #browser,
        :root #navigator-toolbox {
            -moz-default-appearance: menupopup !important;
            appearance: auto !important;
            background-color: transparent !important;
        }

        /*--------- Borders -----------*/

        /* Themed border and rounded corners for browser content */
        #appcontent {
            margin-top: 1px !important;
            margin-inline: 2px !important; /* sides */
            margin-block-end: 2px !important; /* bottom */
            border-radius: 12px !important;
            border: 1px solid var(--accent-dim) !important;
            overflow: hidden !important;
            box-shadow: 0 0 0px 1px var(--accent-secondary) !important;
        }

        .tabbrowser-tab::after {
            border: 0 !important;
        }
        .titlebar-spacer[type="pre-tabs"] {
            border: 0 !important;
        }
        #navigator-toolbox {
            border: 1 !important;
        }

        .titlebar-spacer[type="pre-tabs"] {
            border: 0 !important;
        }

        .tabbrowser-tab::after {
            border: 0 !important;
        }

        #urlbar-background {
            border: 1px solid var(--accent-dim) !important;
        }

        #urlbar[open] > .urlbarView > .urlbarView-body-outer > .urlbarView-body-inner {
            border-top: 0 !important;
        }

        /* Add Transparency and Acrylic Effects */
        :root#main-window {
            background-color: transparent !important;
        }

        :root:not(:-moz-window-inactive) #navigator-toolbox {
            background-color: transparent !important;
            backdrop-filter: blur(calc(var(--blur-amount) * 0.8)) !important;
        }

        /* Enhanced acrylic effects for tabs and toolbar */
        #TabsToolbar {
            background: color-mix(in srgb, var(--bg-overlay) 70%, transparent) !important;
            backdrop-filter: blur(var(--blur-amount)) saturate(1.8) !important;
        }

        #nav-bar {
            background: color-mix(in srgb, var(--bg-overlay) 60%, transparent) !important;
            backdrop-filter: blur(calc(var(--blur-amount) * 0.6)) saturate(1.5) !important;
            border-bottom: 1px solid color-mix(in srgb, var(--accent-dim) 30%, transparent) !important;
        }

        /*--------- Active tab -----------*/

        .tab-background[selected],
        .tab-background[multiselected="true"] {
            background: var(--bg-overlay) !important;
            border: 1px solid var(--accent-secondary) !important;
            border-radius: 8px !important;
        }

        /*--------- Inactive Address/Search Field Background -----------*/

        #urlbar-background {
            background-color: var(--bg-overlay) !important;
            border-radius: 8px !important;
            backdrop-filter: blur(var(--blur-amount)) !important;
        }

        /*--------- Active Address/Search Field Dropdown -----------*/

        #urlbar[breakout][breakout-extend] > #urlbar-background {
            background: var(--bg-secondary) !important;
            border: 1px solid var(--accent-primary) !important;
        }

        /*-------------- URL bar -----------------*/

        /* Centre URL bar text input */
        #urlbar-input {
            height: 100%;
            text-align: center !important;
            color: var(--text-primary) !important;
        }

        /* Unless text input is selected like Safari */
        #urlbar[focused] #urlbar-input {
            position: absolute;
            transform: translateX(0);
            transition: all 0.2s ease;
            width: 100%;
            text-align: left !important;
        }

        #urlbar {
            max-width: 70% !important;
            margin: 0 15% !important;
        }

        /*--------- Navigation Bar Separator -----------*/

        #navigator-toolbox {
            border-color: var(--accent-dim) !important;
        }

        /*--------- Navigation bar Buttons -----------*/
        :root, toolbar {
            --toolbarbutton-hover-background: var(--accent-dim) !important;
        }

        /* Show Tab close button on hover */

        .tabbrowser-tab:not([pinned]) .tab-close-button {
            display: -moz-box !important;
            opacity: 0;
            visibility: collapse !important;
            transition: opacity 0.25s, visibility 0.25s ease-in !important;
        }
        .tabbrowser-tab:not([pinned]):hover .tab-close-button {
            opacity: 1;
            visibility: visible !important;
            border-radius: 3px 3px 3px 3px !important;
        }

        /*--------- Brave Icons -----------*/

        /* Change Reload Button */
        #reload-button {
            list-style-image: url("./brave-icons/Reload.svg") !important;
        }

        /* Change Back Button */
        #back-button {
            list-style-image: url("./brave-icons/BackButton.svg") !important;
        }

        /* Change Forward Button */
        #forward-button {
            list-style-image: url("./brave-icons/ForwardButton.svg") !important;
        }

        /* Change Bookmark Icon */
        #star-button {
            list-style-image: url("./brave-icons/Bookmark.svg") !important;
        }
        #star-button[starred] {
            list-style-image: url("./brave-icons/BookmarkFilled.svg") !important;
        }

        /* Change Search Button */
        #urlbar[pageproxystate="invalid"] #identity-icon,
        .searchbar-search-icon,
        #PopupAutoCompleteRichResult .ac-type-icon[type="keyword"],
        #PopupAutoCompleteRichResult .ac-site-icon[type="searchengine"],
        #appMenu-find-button,
        #panelMenu_searchBookmarks {
            list-style-image: url("./brave-icons/Search.svg") !important;
        }

        /* Change Close Button */
        .tab-close-button {
            list-style-image: url("./brave-icons/CloseTab.svg") !important;
            width: 16px !important;
            height: 16px !important;
            margin: 0 !important;
            padding: 0 !important;
        }

        /*--------- Tab Overflow -----------*/
        .tabbrowser-tab {
            min-width: 0px !important;
        }
        .tab-content {
            overflow: hidden !important;
        }

        /* Tab text color */
        .tab-label {
            color: var(--text-primary) !important;
        }

        .tab-background[selected] .tab-label {
            color: var(--text-primary) !important;
        }

        /* Toolbar button colors */
        .toolbarbutton-1 {
            fill: var(--text-primary) !important;
        }
      '';

      baseUserContentCSS = ''
        /* Semantic theme-aware userContent.css */

        /* Acrylic background with blur wallpaper */
        @media (prefers-color-scheme: light) {
          :root {
            --background-wallpaper: linear-gradient(135deg,
              var(--bg-primary) 0%,
              color-mix(in srgb, var(--bg-primary) 80%, var(--accent-dim) 20%) 50%,
              var(--bg-secondary) 100%);
          }
        }

        @media (prefers-color-scheme: dark) {
          :root {
            --background-wallpaper: linear-gradient(135deg,
              var(--bg-primary) 0%,
              color-mix(in srgb, var(--bg-primary) 85%, var(--accent-primary) 15%) 30%,
              color-mix(in srgb, var(--bg-secondary) 90%, var(--accent-secondary) 10%) 70%,
              var(--bg-tertiary) 100%);
          }
        }

        @-moz-document url-prefix(about:home), url-prefix(about:newtab) {
          body {
            background: var(--background-wallpaper) !important;
            background-attachment: fixed !important;
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
        userChromeCSS = semanticCSSVariables + baseChromeCSS;
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
