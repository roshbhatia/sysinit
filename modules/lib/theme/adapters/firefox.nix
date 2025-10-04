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
        Minimal Modern Firefox Theme with Semantic Colors
        Clean, minimal aesthetic with smooth animations and blur effects
        --------------------------------------------------------------------------------- */

        /* ========== CORE TRANSPARENCY & BLUR ========== */

        :root#main-window {
            background-color: transparent !important;
        }

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

        :root:not(:-moz-window-inactive) #navigator-toolbox {
            background-color: transparent !important;
            backdrop-filter: blur(calc(var(--blur-amount) * 0.8)) saturate(1.5) !important;
        }

        /* ========== MINIMAL TOOLBAR STYLING ========== */

        #TabsToolbar {
            background: color-mix(in srgb, var(--bg-overlay) 65%, transparent) !important;
            backdrop-filter: blur(var(--blur-amount)) saturate(1.8) !important;
            padding-block: 4px !important;
            border-bottom: none !important;
        }

        #nav-bar {
            background: color-mix(in srgb, var(--bg-overlay) 55%, transparent) !important;
            backdrop-filter: blur(calc(var(--blur-amount) * 0.7)) saturate(1.5) !important;
            border: none !important;
            box-shadow: none !important;
            padding-block: 6px !important;
        }

        #navigator-toolbox {
            border: none !important;
        }

        /* ========== MINIMAL TABS ========== */

        /* Remove all tab borders and separators */
        .tabbrowser-tab::after,
        .tabbrowser-tab::before {
            display: none !important;
        }

        /* Minimal tab styling */
        .tabbrowser-tab {
            min-width: 0px !important;
            padding-inline: 4px !important;
        }

        .tab-background {
            border: none !important;
            box-shadow: none !important;
            border-radius: 6px !important;
            margin-block: 2px !important;
            transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1) !important;
        }

        /* Inactive tabs - nearly invisible */
        .tab-background:not([selected]) {
            background: transparent !important;
        }

        .tabbrowser-tab:not([selected]):hover .tab-background {
            background: color-mix(in srgb, var(--bg-overlay) 40%, transparent) !important;
        }

        /* Active tab - subtle highlight */
        .tab-background[selected],
        .tab-background[multiselected="true"] {
            background: color-mix(in srgb, var(--bg-overlay) 80%, transparent) !important;
            box-shadow: 0 0 0 1px color-mix(in srgb, var(--accent-secondary) 30%, transparent) !important;
        }

        /* Tab content */
        .tab-content {
            overflow: hidden !important;
            padding-inline: 8px !important;
        }

        /* Tab labels - clean typography */
        .tab-label {
            color: var(--text-secondary) !important;
            font-weight: 400 !important;
            transition: color 0.2s ease !important;
        }

        .tab-background[selected] .tab-label {
            color: var(--text-primary) !important;
            font-weight: 500 !important;
        }

        /* Tab close button - only show on hover */
        .tabbrowser-tab:not([pinned]) .tab-close-button {
            display: -moz-box !important;
            opacity: 0 !important;
            visibility: collapse !important;
            transition: opacity 0.2s ease, visibility 0.2s ease !important;
            list-style-image: url("./brave-icons/CloseTab.svg") !important;
            width: 16px !important;
            height: 16px !important;
            margin: 0 !important;
            padding: 0 !important;
            border-radius: 3px !important;
        }

        .tabbrowser-tab:not([pinned]):hover .tab-close-button {
            opacity: 0.7 !important;
            visibility: visible !important;
        }

        .tabbrowser-tab:not([pinned]) .tab-close-button:hover {
            opacity: 1 !important;
            background: var(--accent-dim) !important;
        }

        /* Remove tab separators */
        .titlebar-spacer[type="pre-tabs"] {
            border: none !important;
        }

        /* ========== MINIMAL URL BAR ========== */

        #urlbar-container {
            max-width: 65% !important;
            margin: 0 auto !important;
        }

        #urlbar {
            border: none !important;
        }

        #urlbar-background {
            background: color-mix(in srgb, var(--bg-overlay) 70%, transparent) !important;
            border: 1px solid color-mix(in srgb, var(--accent-dim) 40%, transparent) !important;
            border-radius: 8px !important;
            backdrop-filter: blur(var(--blur-amount)) !important;
            box-shadow: none !important;
            outline: none !important;
            transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1) !important;
        }

        /* URL bar on hover/focus */
        #urlbar:hover > #urlbar-background,
        #urlbar[focused] > #urlbar-background {
            background: color-mix(in srgb, var(--bg-overlay) 85%, transparent) !important;
            border-color: var(--accent-secondary) !important;
            box-shadow: 0 2px 8px color-mix(in srgb, var(--accent-primary) 15%, transparent) !important;
        }

        /* URL bar dropdown */
        #urlbar[breakout][breakout-extend] > #urlbar-background {
            background: var(--bg-secondary) !important;
            border-color: var(--accent-primary) !important;
        }

        #urlbar[open] > .urlbarView > .urlbarView-body-outer > .urlbarView-body-inner {
            border-top: none !important;
        }

        /* Center URL text (Safari style) */
        #urlbar-input {
            text-align: center !important;
            color: var(--text-primary) !important;
            transition: text-align 0.2s ease !important;
        }

        #urlbar[focused] #urlbar-input {
            text-align: left !important;
        }

        /* ========== MINIMAL CONTENT AREA ========== */

        #appcontent {
            margin-top: 0px !important;
            margin-inline: 1px !important;
            margin-block-end: 1px !important;
            border-radius: 10px !important;
            border: 1px solid color-mix(in srgb, var(--accent-dim) 25%, transparent) !important;
            overflow: hidden !important;
            box-shadow: 0 1px 3px color-mix(in srgb, var(--accent-secondary) 10%, transparent) !important;
        }

        /* ========== TOOLBAR BUTTONS ========== */

        :root, toolbar {
            --toolbarbutton-hover-background: color-mix(in srgb, var(--accent-dim) 60%, transparent) !important;
            --toolbarbutton-active-background: var(--accent-dim) !important;
        }

        .toolbarbutton-1 {
            fill: var(--text-secondary) !important;
            border-radius: 6px !important;
            transition: all 0.2s ease !important;
        }

        .toolbarbutton-1:hover {
            fill: var(--text-primary) !important;
            background: var(--toolbarbutton-hover-background) !important;
        }

        /* Navigation button icons */
        #back-button {
            list-style-image: url("./brave-icons/BackButton.svg") !important;
        }

        #forward-button {
            list-style-image: url("./brave-icons/ForwardButton.svg") !important;
        }

        #reload-button {
            list-style-image: url("./brave-icons/Reload.svg") !important;
        }

        #star-button {
            list-style-image: url("./brave-icons/Bookmark.svg") !important;
        }

        #star-button[starred] {
            list-style-image: url("./brave-icons/BookmarkFilled.svg") !important;
        }

        #urlbar[pageproxystate="invalid"] #identity-icon,
        .searchbar-search-icon,
        #PopupAutoCompleteRichResult .ac-type-icon[type="keyword"],
        #PopupAutoCompleteRichResult .ac-site-icon[type="searchengine"],
        #appMenu-find-button,
        #panelMenu_searchBookmarks {
            list-style-image: url("./brave-icons/Search.svg") !important;
        }

        /* ========== CLEAN UP VISUAL NOISE ========== */

        /* Remove unnecessary shadows */
        .tabbrowser-tab:is([visuallyselected="true"], [multiselected]) > .tab-stack > .tab-background {
            box-shadow: none !important;
        }

        /* Hide bookmark bar by default (can be toggled with Cmd+Shift+B) */
        #PersonalToolbar {
            min-height: 0 !important;
            max-height: 0 !important;
            margin: 0 !important;
            padding: 0 !important;
        }

        /* Show bookmark bar when customizing or when explicitly shown */
        #PersonalToolbar:not([collapsed="true"]) {
            min-height: auto !important;
            max-height: none !important;
            padding-block: 4px !important;
        }

        /* ========== SMOOTH ANIMATIONS ========== */

        * {
            transition-timing-function: cubic-bezier(0.4, 0, 0.2, 1) !important;
        }

        /* Smooth tab animations */
        .tabbrowser-tab {
            transition: opacity 0.2s ease !important;
        }

        /* Smooth toolbar transitions */
        #nav-bar, #TabsToolbar {
            transition: background 0.2s ease, backdrop-filter 0.2s ease !important;
        }

        /* ========== COMPACT MODE REFINEMENTS ========== */

        /* Reduce padding in compact mode */
        :root[uidensity="compact"] #TabsToolbar {
            padding-block: 2px !important;
        }

        :root[uidensity="compact"] #nav-bar {
            padding-block: 4px !important;
        }

        :root[uidensity="compact"] .tab-content {
            padding-inline: 6px !important;
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
