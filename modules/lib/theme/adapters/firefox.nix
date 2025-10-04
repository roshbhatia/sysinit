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
        Minimal Firefox Theme - Clean, Ghostty-inspired
        Simple, functional, minimal design with theme integration
        --------------------------------------------------------------------------------- */

        /* ========== TYPOGRAPHY ========== */

        * {
            font-family: "TX-02", -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif !important;
        }

        /* ========== BASE STYLING ========== */

        :root {
            --minimal-bg: ${semanticColors.background.primary};
            --minimal-bg-secondary: ${semanticColors.background.secondary};
            --minimal-text: ${semanticColors.foreground.primary};
            --minimal-text-secondary: ${semanticColors.foreground.secondary};
            --minimal-accent: ${semanticColors.accent.primary};
            --minimal-border: ${semanticColors.accent.dim};
        }

        :root #TabsToolbar,
        :root #titlebar,
        :root #tabbrowser-tabs,
        :root #PersonalToolbar,
        :root #nav-bar,
        :root #browser,
        :root #navigator-toolbox {
            -moz-appearance: none !important;
            appearance: none !important;
        }

        #navigator-toolbox {
            border: none !important;
            background-color: var(--minimal-bg) !important;
        }

        /* ========== MINIMAL TOOLBAR ========== */

        #TabsToolbar {
            background: var(--minimal-bg) !important;
            padding-block: 4px !important;
            padding-inline: 8px !important;
            border: none !important;
            min-height: 32px !important;
            max-height: 32px !important;
        }

        #nav-bar {
            background: var(--minimal-bg) !important;
            border: none !important;
            padding-block: 4px !important;
            padding-inline: 8px !important;
            min-height: 32px !important;
        }

        .tabbrowser-arrowscrollbox {
            height: 32px !important;
            min-height: 32px !important;
        }

        /* ========== MINIMAL SQUARE TABS ========== */

        /* Remove tab separators */
        .tabbrowser-tab::after,
        .tabbrowser-tab::before {
            display: none !important;
            border-left: none !important;
        }

        .titlebar-spacer[type="pre-tabs"],
        .titlebar-spacer[type="post-tabs"] {
            display: none !important;
        }

        /* Square tabs - clean and simple */
        .tabbrowser-tab {
            min-width: 0px !important;
            padding-inline: 2px !important;
        }

        .tab-background {
            border: none !important;
            box-shadow: none !important;
            border-radius: 0 !important;
            margin: 0 !important;
            transition: background-color 0.1s ease !important;
        }

        /* Inactive tabs - subtle */
        .tab-background:not([selected]) {
            background: var(--minimal-bg) !important;
        }

        .tabbrowser-tab:not([selected]):hover .tab-background {
            background: var(--minimal-bg-secondary) !important;
        }

        /* Active tab - simple highlight */
        .tab-background[selected],
        .tab-background[multiselected="true"] {
            background: var(--minimal-bg-secondary) !important;
        }

        /* Tab content - minimal spacing */
        .tab-content {
            overflow: hidden !important;
            padding-inline: 8px !important;
            padding-block: 4px !important;
        }

        /* Tab labels - clean, centered like minimalfox */
        .tab-label {
            -moz-box-flex: 1 !important;
            text-align: center !important;
            color: var(--minimal-text-secondary) !important;
            font-weight: 400 !important;
            font-size: 11px !important;
        }

        .tab-background[selected] .tab-label {
            color: var(--minimal-text) !important;
            font-weight: 600 !important;
        }

        /* Tab close button - only show on hover */
        .tabbrowser-tab:not([pinned]):not(:hover) .tab-close-button {
            visibility: collapse !important;
        }

        .tabbrowser-tab:not([pinned]):hover .tab-close-button {
            visibility: visible !important;
            display: block !important;
        }

        .tab-close-button {
            list-style-image: url("./brave-icons/CloseTab.svg") !important;
            width: 16px !important;
            height: 16px !important;
            margin: 0 !important;
            padding: 0 !important;
            border-radius: 2px !important;
        }

        .tab-close-button:hover {
            background: var(--minimal-border) !important;
        }

        /* ========== MINIMAL URL BAR ========== */

        #urlbar-container {
            min-width: 169px !important;
        }

        #urlbar {
            background: transparent !important;
            border: none !important;
            box-shadow: none !important;
        }

        #urlbar-background {
            background: var(--minimal-bg-secondary) !important;
            border: none !important;
            border-radius: 4px !important;
            box-shadow: none !important;
        }

        #urlbar[focused="true"] > #urlbar-background,
        #urlbar:hover > #urlbar-background {
            border-color: var(--minimal-border) !important;
        }

        #urlbar[open] > #urlbar-background {
            border-color: transparent !important;
        }

        /* Clean URL input */
        #urlbar .urlbar-input-box {
            text-align: left !important;
        }

        #urlbar-input {
            color: var(--minimal-text) !important;
            font-size: 12px !important;
        }

        .urlbar-input-box > .urlbar-input::placeholder {
            opacity: 0 !important;
        }

        /* ========== MINIMAL CONTENT AREA ========== */

        #appcontent {
            margin: 0 !important;
            border: none !important;
            border-radius: 0 !important;
        }

        .browserContainer {
            background-color: var(--minimal-bg) !important;
        }

        /* ========== MINIMAL TOOLBAR BUTTONS ========== */

        toolbar .toolbarbutton-1 {
            -moz-appearance: none !important;
            appearance: none !important;
            margin: -1px !important;
            padding: 0 var(--toolbarbutton-outer-padding) !important;
        }

        .toolbarbutton-1 {
            fill: var(--minimal-text-secondary) !important;
            border-radius: 2px !important;
        }

        .toolbarbutton-1:hover {
            background: var(--minimal-bg-secondary) !important;
        }

        /* Hide back/forward buttons for clean look */
        #back-button,
        #forward-button {
            display: none !important;
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

        /* Hide page action buttons for minimal look */
        #page-action-buttons {
            display: none !important;
        }

        /* Hide hamburger menu button */
        #PanelUI-button {
            display: none !important;
        }

        /* ========== MINIMAL CLEAN UI ========== */

        /* Hide bookmarks toolbar */
        #PersonalToolbar {
            display: none !important;
        }

        /* Hide window controls container for cleaner titlebar */
        .titlebar-buttonbox-container {
            display: none !important;
        }

        /* Hide new tab button */
        #tabs-newtab-button {
            display: none !important;
        }

        /* Hide identity icon extensions */
        #identity-icon {
            visibility: visible !important;
        }

        #tracking-protection-icon-container {
            visibility: collapse !important;
        }

        /* ========== MINIMAL CONTEXT MENUS ========== */

        :root {
            --uc-menu-bkgnd: var(--minimal-bg-secondary);
            --uc-menu-color: var(--minimal-text);
            --uc-menu-dimmed: var(--minimal-border);
            --uc-menu-disabled: var(--minimal-text-secondary);
        }

        panel richlistbox,
        panel tree,
        panel button,
        panel menulist,
        panel textbox,
        panel input,
        menupopup,
        menu,
        menuitem {
            -moz-appearance: none !important;
        }

        menulist,
        menuitem,
        menu {
            min-height: 1.8em !important;
        }

        panel richlistbox,
        panel tree,
        panel button,
        panel menulist,
        panel textbox,
        panel input,
        menupopup,
        #main-menubar > menu > menupopup,
        #context-navigation {
            color: var(--uc-menu-color) !important;
            padding: 2px !important;
            background-color: var(--uc-menu-bkgnd) !important;
            border-color: var(--uc-menu-disabled) !important;
            border-radius: 4px !important;
        }

        menu:hover,
        menu[_moz-menuactive],
        menu[open],
        menuitem:hover,
        menuitem[_moz-menuactive] {
            background-color: var(--uc-menu-dimmed) !important;
            color: inherit !important;
        }

        menu[disabled="true"],
        menuitem[disabled="true"] {
            color: var(--uc-menu-disabled) !important;
        }

        /* ========== MINIMAL SIDEBAR ========== */

        #sidebar-box,
        #sidebar,
        .sidebar-placesTree {
            -moz-appearance: none !important;
            color: var(--minimal-text) !important;
            background-color: var(--minimal-bg) !important;
        }

        /* ========== MINIMAL TOOLTIPS ========== */

        tooltip {
            -moz-appearance: none !important;
            color: var(--minimal-text) !important;
            background-color: var(--minimal-bg-secondary) !important;
            padding: 6px !important;
            border-radius: 4px !important;
            box-shadow: none !important;
            text-align: center !important;
        }

        /* ========== FINAL POLISH ========== */

        #navigator-toolbox::after {
            display: none !important;
        }

        :root {
            --toolbox-border-bottom-color: transparent !important;
        }
      '';

      baseUserContentCSS = ''
        /* Minimal New Tab & Content Pages */

        :root {
            --minimal-bg: ${semanticColors.background.primary};
            --minimal-bg-secondary: ${semanticColors.background.secondary};
            --minimal-text: ${semanticColors.foreground.primary};
            --minimal-text-secondary: ${semanticColors.foreground.secondary};
            --minimal-accent: ${semanticColors.accent.primary};
            --minimal-border: ${semanticColors.accent.dim};
        }

        @-moz-document url-prefix(about:home), url-prefix(about:newtab) {
          * {
            font-family: "TX-02", -apple-system, BlinkMacSystemFont, sans-serif !important;
          }

          body {
            background: var(--minimal-bg) !important;
            background-attachment: fixed !important;
            color: var(--minimal-text) !important;
          }

          /* Minimal search bar */
          .search-wrapper {
            background: transparent !important;
          }

          .search-handoff-button {
            background: var(--minimal-bg-secondary) !important;
            border: 1px solid var(--minimal-border) !important;
            color: var(--minimal-text) !important;
            border-radius: 4px !important;
            padding: 12px 16px !important;
            font-size: 12px !important;
          }

          .search-handoff-button:hover {
            background: var(--minimal-border) !important;
          }

          /* Minimal top sites */
          .top-site-outer {
            background: var(--minimal-bg-secondary) !important;
            border: 1px solid var(--minimal-border) !important;
            border-radius: 4px !important;
          }

          .top-site-outer:hover {
            background: var(--minimal-border) !important;
          }

          /* Minimal menus */
          .customize-menu,
          .context-menu {
            background: var(--minimal-bg-secondary) !important;
            border: 1px solid var(--minimal-border) !important;
            border-radius: 4px !important;
            padding: 4px !important;
          }

          .context-menu-item {
            border-radius: 2px !important;
          }

          .context-menu-item:hover {
            background: var(--minimal-border) !important;
          }

          /* Minimal cards */
          .ds-card {
            background: var(--minimal-bg-secondary) !important;
            border: 1px solid var(--minimal-border) !important;
            border-radius: 4px !important;
          }

          .ds-card:hover {
            background: var(--minimal-border) !important;
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
