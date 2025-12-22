{
  lib,
  utils,
  ...
}:

with lib;

{
  createFirefoxConfig =
    themeData: config: overrides:
    let
      palette = themeData.palettes.${config.variant};
      semanticColors = utils.createSemanticMapping palette;
      transparency = config.transparency or (throw "Missing transparency configuration");

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

      monospaceFont =
        if hasAttr "font" config && hasAttr "monospace" config.font then
          config.font.monospace
        else
          "JetBrainsMono Nerd Font";

      baseChromeCSS = ''
        /* ========== TYPOGRAPHY ========== */

        * {
            font-family: "${monospaceFont}", -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif !important;
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

        /* ========== TOOLBAR ALWAYS VISIBLE ========== */

        #navigator-toolbox {
            background-color: var(--minimal-bg) !important;
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
            padding: 4px var(--toolbarbutton-outer-padding) 0 !important;
            -moz-box-pack: center;
        }

        /* Extra breathing room for nav-bar icons */
        #nav-bar .toolbarbutton-1 {
            padding-top: 6px !important;
        }

        .titlebar-placeholder[type="pre-tabs"] {
            display: none !important;
        }

        :root {
            --toolbox-border-bottom-color: transparent !important;
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
        #nav-bar,
        #urlbar-background {
            background: var(--minimal-bg) !important;
        }

        /* Urlbar inner background should be secondary */
        #urlbar-background {
            background: var(--minimal-bg-secondary) !important;
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
            min-width: 600px !important;
            flex: 1 !important;
            padding-top: 6px !important;
            margin-top: 2px !important;
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

        /* Set toolbar field colors for both light and dark themes */
        :root {
            --lwt-toolbar-field-background-color: var(--minimal-bg-secondary) !important;
            --lwt-toolbar-field-border-color: var(--minimal-bg-secondary) !important;
            --lwt-toolbar-field-focus: var(--minimal-bg-secondary) !important;
            --toolbar-bgcolor: var(--minimal-bg) !important;
            --toolbar-field-background-color: var(--minimal-bg-secondary) !important;
            --toolbar-field-focus-background-color: var(--minimal-bg-secondary) !important;
        }

        #page-action-buttons {
            display: none !important;
        }

        #urlbar .urlbar-input-box {
            text-align: left;
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

        /* ========== HIDE SIDEBAR ALWAYS ========== */

        #sidebar-box {
            display: none !important;
            visibility: hidden !important;
        }

        #sidebar-splitter {
            display: none !important;
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
            font-family: "${monospaceFont}", -apple-system, BlinkMacSystemFont, sans-serif !important;
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
        inherit semanticColors;
        inherit transparency;
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
      inherit (config) variant;
      appearance = if hasAttr "appearance" config then config.appearance else null;
      font = if hasAttr "font" config then config.font else null;
      transparency = config.transparency or (throw "Missing transparency configuration");
      inherit semanticColors palette;
      theme_identifier = "${themeData.meta.id}-${config.variant}";
    };
}
