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
        minimalFOX - Compact & Minimal Firefox Theme
        Based on https://github.com/marmmaz/FirefoxCSS
        With theme color integration
        --------------------------------------------------------------------------------- */

        /* ========== TYPOGRAPHY ========== */

        * {
            font-family: "TX-02", -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif !important;
        }

        /* ========== THEME COLORS ========== */

        :root {
            --minimal-bg: ${semanticColors.background.primary};
            --minimal-bg-secondary: ${semanticColors.background.secondary};
            --minimal-text: ${semanticColors.foreground.primary};
            --minimal-text-secondary: ${semanticColors.foreground.secondary};
            --minimal-accent: ${semanticColors.accent.primary};
            --minimal-border: ${semanticColors.accent.dim};
        }

        /* ========== AUTO-HIDE TOOLBAR ========== */

        :root {
            --uc-autohide-toolbox-delay: 200ms;
            --uc-toolbox-rotation: 65deg;
        }

        :root[sizemode="maximized"] {
            --uc-toolbox-rotation: 63deg;
        }

        @media (-moz-os-version: windows-win10) {
            :root[tabsintitlebar][sizemode="maximized"]:not([inDOMFullscreen]) > body > box {
                margin-top: 9px !important;
            }
            :root[tabsintitlebar][sizemode="maximized"] #navigator-toolbox {
                margin-top: -1px;
            }
        }

        :root[sizemode="fullscreen"] {
            margin-top: 0px !important;
        }

        #navigator-toolbox {
            position: fixed !important;
            display: block;
            background-color: var(--minimal-bg) !important;
            transition: transform 82ms linear, opacity 82ms linear !important;
            transition-delay: var(--uc-autohide-toolbox-delay) !important;
            transform-origin: top;
            transform: rotateX(var(--uc-toolbox-rotation));
            opacity: 0;
            line-height: 0;
            z-index: 1;
            pointer-events: none;
        }

        #navigator-toolbox:hover,
        #navigator-toolbox:focus-within {
            transition-delay: 33ms !important;
            transform: rotateX(0);
            opacity: 1;
        }

        #navigator-toolbox > * {
            line-height: normal;
            pointer-events: auto;
        }

        #navigator-toolbox,
        #navigator-toolbox > * {
            width: 100vw;
            -moz-appearance: none !important;
        }

        :root:not([sessionrestored]) #navigator-toolbox {
            transform: none !important;
        }

        :root[customizing] #navigator-toolbox {
            position: relative !important;
            transform: none !important;
            opacity: 1 !important;
        }

        #navigator-toolbox[inFullscreen] > #PersonalToolbar,
        #PersonalToolbar[collapsed="true"] {
            display: none;
        }

        /* ========== TOOLBAR & WINDOW CONTROLS ========== */

        .titlebar-buttonbox-container {
            display: none;
        }

        #navigator-toolbox {
            border: 0px !important;
        }

        toolbar .toolbarbutton-1 {
            -moz-appearance: none !important;
            appearance: none !important;
            margin: -1px;
            padding: 0 var(--toolbarbutton-outer-padding);
            -moz-box-pack: center;
        }

        #TabsToolbar {
            margin-top: -1px !important;
            margin-bottom: 1px !important;
            margin-left: 26vw !important;
            max-height: 32px !important;
        }

        .tabbrowser-arrowscrollbox {
            height: 32px !important;
            min-height: 32px !important;
        }

        .titlebar-placeholder[type="pre-tabs"] {
            display: none !important;
        }

        :root {
            --toolbox-border-bottom-color: transparent !important;
        }

        #nav-bar {
            background: transparent !important;
            margin-top: -32px !important;
            margin-bottom: -1px !important;
            margin-right: 72vw !important;
            height: 32px !important;
        }

        /* ========== TABS ========== */

        .tabbrowser-tab::before,
        .tabbrowser-tab::after {
            border-left: none !important;
        }

        .tab-background:not([selected=true]),
        .tab-background[selected="true"],
        #titlebar-buttonbox,
        #TabsToolbar,
        #PersonalToolbar,
        #urlbar,
        #urlbar-container,
        #nav-bar {
            background: var(--minimal-bg) !important;
        }

        /* Centered tab labels */
        .tab-label {
            -moz-box-flex: 1 !important;
            text-align: center !important;
            font-size: 10px !important;
            color: var(--minimal-text-secondary) !important;
        }

        #TabsToolbar .tabbrowser-tab[selected] {
            color: var(--minimal-text) !important;
            font-weight: bold !important;
            font-size: 10px !important;
        }

        /* Tab close button - only on hover */
        .tabbrowser-tab:not([pinned]):not(:hover) .tab-close-button {
            visibility: collapse !important;
        }

        .tabbrowser-tab:not([pinned]):hover .tab-close-button {
            visibility: visible !important;
            display: block !important;
        }

        /* Auto-hide scrollbar */
        scrollbar {
            -moz-appearance: none !important;
            background: transparent !important;
            width: 0px !important;
        }

        scrollbar thumb {
            background-color: var(--minimal-border) !important;
        }

        * {
            scrollbar-width: none !important;
        }

        /* ========== URL BAR ========== */

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
        }

        :root:-moz-lwtheme-brighttext {
            --lwt-toolbar-field-background-color: var(--minimal-bg-secondary) !important;
            --lwt-toolbar-field-border-color: var(--minimal-bg-secondary) !important;
            --lwt-toolbar-field-focus: var(--minimal-bg-secondary) !important;
            --toolbar-bgcolor: var(--minimal-bg-secondary) !important;
        }

        #page-action-buttons {
            display: none !important;
        }

        #back-button,
        #forward-button {
            display: none !important;
        }

        #urlbar .urlbar-input-box {
            text-align: left;
        }

        #PanelUI-button {
            display: none;
        }

        .bookmark-item > .toolbarbutton-icon {
            display: none !important;
        }

        #PlacesToolbarItems > .bookmark-item > .toolbarbutton-icon[label]: {
            margin-inline-end: 0px !important;
        }

        .tabbrowser-tab::after,
        .tabbrowser-tab::before {
            border-left: none !important;
        }

        .urlbar-history-dropmarker,
        #urlbar:hover > .urlbar-textbox-container > .urlbar-history-dropmarker {
            display: none !important;
        }

        #personal-bookmarks #PlacesToolbarItems {
            -moz-box-pack: center;
        }

        .urlbar-input-box > .urlbar-input::placeholder {
            opacity: 0 !important;
        }

        /* Hide extension names */
        #identity-box.extensionPage #identity-icon-labels,
        #identity-box.extensionPage #identity-icon-label {
            visibility: collapse !important;
            transition: visibility 250ms ease-in-out;
        }

        #identity-box.extensionPage:hover #identity-icon-labels,
        #identity-box.extensionPage:hover #identity-icon-label {
            visibility: collapse !important;
            transition: visibility 250ms ease-in-out 500ms;
        }

        #tracking-protection-icon-container {
            visibility: collapse !important;
        }

        #identity-icon {
            visibility: visible !important;
        }

        #urlbar[open] > #urlbar-background {
            border-color: transparent !important;
        }

        #urlbar[focused="true"] > #urlbar-background,
        #searchbar:focus-within {
            border-color: var(--lwt-toolbar-field-border-color, hsla(240, 5%, 5%, 0.35)) !important;
        }

        /* ========== CONTENT AREA ========== */

        .browserContainer {
            background-color: var(--minimal-bg) !important;
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
