{
  lib,
  utils,
  ...
}:

with lib;

{
  createFirefoxConfig =
    _themeData: config: overrides:
    let
      transparency = config.transparency or (throw "Missing transparency configuration");

      # Note: Firefox theming now handled by stylix
      # This function is kept for compatibility but returns minimal config
      semanticColors = {
        background = {
          primary = "#000000";
          secondary = "#111111";
          tertiary = "#222222";
          overlay = "#333333";
        };
        foreground = {
          primary = "#ffffff";
          secondary = "#eeeeee";
          muted = "#cccccc";
          subtle = "#aaaaaa";
        };
        accent = {
          primary = "#0066cc";
          secondary = "#00cccc";
          tertiary = "#cc00cc";
          dim = "#333333";
        };
        semantic = {
          error = "#ff0000";
          warning = "#ffcc00";
          success = "#00ff00";
          info = "#0066cc";
        };
        extended = { };
      };

      paletteBaseColors =
        let
          extendedPalette = semanticColors.extended or { };
          getColor = name: fallback: extendedPalette.${name} or fallback;
        in
        {
          red = getColor "red" semanticColors.semantic.error;
          orange = getColor "orange" semanticColors.accent.secondary;
          yellow = getColor "yellow" semanticColors.semantic.warning;
          green = getColor "green" semanticColors.semantic.success;
          cyan = getColor "cyan" semanticColors.accent.secondary;
          blue = getColor "blue" semanticColors.accent.primary;
          purple = getColor "purple" semanticColors.accent.tertiary;
        };

      semanticCSSVariables = ''
        /* Semantic theme colors for Firefox */
        :root {
          /* Background colors */
          --bg-primary: ${semanticColors.background.primary};
          --bg-secondary: ${semanticColors.background.secondary};
          --bg-tertiary: ${semanticColors.background.tertiary};
          --bg-overlay: ${semanticColors.background.overlay};

          /* Text colors - semantic hierarchy */
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

          /* Base16-style colors (for advanced customization) */
          --color-red: ${paletteBaseColors.red};
          --color-orange: ${paletteBaseColors.orange};
          --color-yellow: ${paletteBaseColors.yellow};
          --color-green: ${paletteBaseColors.green};
          --color-cyan: ${paletteBaseColors.cyan};
          --color-blue: ${paletteBaseColors.blue};
          --color-purple: ${paletteBaseColors.purple};

          /* Transparency and blur effects */
          --opacity: ${toString transparency.opacity};
          --blur-amount: ${toString transparency.blur}px;

          /* Interactive element states - derived for better contrast */
          --interactive-hover-bg: var(--bg-secondary);
          --interactive-active-bg: var(--accent-primary);
          --interactive-active-fg: var(--bg-primary);
          --interactive-focus-outline: var(--accent-primary);
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

        /* ========== BUTTON & INTERACTIVE ELEMENTS ========== */

        /* Toolbar buttons - explicit text colors for light mode */
        toolbar .toolbarbutton-1,
        toolbar .toolbarbutton-text {
            color: var(--minimal-text) !important;
        }

        /* Toolbar buttons - better hover/active states */
        toolbar .toolbarbutton-1:hover {
            background-color: var(--minimal-border) !important;
            color: var(--minimal-text) !important;
        }

        toolbar .toolbarbutton-1[open],
        toolbar .toolbarbutton-1[checked],
        toolbar .toolbarbutton-1:active {
            background-color: var(--minimal-accent) !important;
            color: var(--minimal-bg) !important;
        }

        toolbar .toolbarbutton-1[open] .toolbarbutton-text,
        toolbar .toolbarbutton-1[checked] .toolbarbutton-text,
        toolbar .toolbarbutton-1:active .toolbarbutton-text {
            color: var(--minimal-bg) !important;
        }

        /* Focus states for accessibility */
        toolbar .toolbarbutton-1:focus-visible {
            outline: 2px solid var(--minimal-accent) !important;
            outline-offset: 1px !important;
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

        /* Tab labels - ensure good contrast in both light and dark modes */
        .tab-label {
            -moz-box-flex: 1 !important;
            text-align: center !important;
            font-size: 10px !important;
            color: var(--minimal-text-secondary) !important;
            transition: color 150ms ease !important;
        }

        /* Unselected tab - improve readability */
        .tabbrowser-tab:not([selected]) .tab-label {
            color: var(--minimal-text-secondary) !important;
        }

        /* Unselected tab hover state - full contrast */
        .tabbrowser-tab:not([selected]):hover .tab-label {
            color: var(--minimal-text) !important;
        }

        /* Selected tab - maximum visibility with bold text */
        #TabsToolbar .tabbrowser-tab[selected] .tab-label {
            color: var(--minimal-text) !important;
            font-weight: bold !important;
            font-size: 10px !important;
        }

        /* Selected tab background with accent underline */
        .tabbrowser-tab[selected] {
            background-color: var(--minimal-bg-secondary) !important;
            border-bottom: 2px solid var(--minimal-accent) !important;
        }

        /* Tab close button - only on hover */
        .tabbrowser-tab:not([pinned]):not(:hover) .tab-close-button {
            visibility: collapse !important;
        }

        .tabbrowser-tab:not([pinned]):hover .tab-close-button {
            visibility: visible !important;
            display: block !important;
        }

        /* Auto-hide scrollbar - with visible thumb for light mode */
        scrollbar {
            -moz-appearance: none !important;
            background: transparent !important;
            width: 0px !important;
        }

        scrollbar thumb {
            background-color: var(--minimal-text-secondary) !important;
            border-radius: 4px !important;
        }

        scrollbar thumb:hover {
            background-color: var(--minimal-text) !important;
        }

        * {
            scrollbar-width: thin !important;
            scrollbar-color: var(--minimal-text-secondary) transparent !important;
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
            border: 1px solid var(--minimal-border) !important;
            border-radius: 4px !important;
            transition: border-color 150ms ease !important;
        }

        /* Urlbar focus state for better contrast & visibility */
        #urlbar:focus-within > #urlbar-background {
            border-color: var(--minimal-accent) !important;
            box-shadow: 0 0 0 2px var(--minimal-bg) !important;
        }

        /* Set toolbar field colors for both light and dark themes */
        :root {
            --lwt-toolbar-field-background-color: var(--minimal-bg-secondary) !important;
            --lwt-toolbar-field-border-color: var(--minimal-border) !important;
            --lwt-toolbar-field-focus: var(--minimal-bg-secondary) !important;
            --toolbar-bgcolor: var(--minimal-bg) !important;
            --toolbar-field-background-color: var(--minimal-bg-secondary) !important;
            --toolbar-field-focus-background-color: var(--minimal-bg-secondary) !important;
            --toolbar-field-focus-border-color: var(--minimal-accent) !important;
        }

        #page-action-buttons {
            display: none !important;
        }

        #urlbar .urlbar-input-box {
            text-align: left;
        }

        /* URLbar input text - explicit color for light mode visibility */
        #urlbar .urlbar-input,
        #urlbar .urlbar-input-box input {
            color: var(--minimal-text) !important;
            caret-color: var(--minimal-accent) !important;
        }

        #urlbar .urlbar-input::selection {
            background-color: var(--minimal-accent) !important;
            color: var(--minimal-bg) !important;
        }

        /* URLbar suggestion popup - ensure dark text on light backgrounds */
        #urlbar-results {
            background-color: var(--minimal-bg-secondary) !important;
        }

        .urlbarView-row {
            background-color: var(--minimal-bg-secondary) !important;
            color: var(--minimal-text) !important;
        }

        .urlbarView-row:hover,
        .urlbarView-row[selected] {
            background-color: var(--minimal-border) !important;
            color: var(--minimal-text) !important;
        }

        .urlbarView-row-inner {
            color: var(--minimal-text) !important;
        }

        .urlbarView-title,
        .urlbarView-url,
        .urlbarView-action {
            color: var(--minimal-text) !important;
        }

        .urlbarView-url {
            color: var(--minimal-text-secondary) !important;
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

        /* ========== FIND BAR ========== */

        #findbar {
            background-color: var(--minimal-bg-secondary) !important;
            color: var(--minimal-text) !important;
            border-color: var(--minimal-border) !important;
        }

        #findbar-textbox,
        #findbar input {
            background-color: var(--minimal-bg) !important;
            color: var(--minimal-text) !important;
            border-color: var(--minimal-border) !important;
        }

        #findbar-textbox::placeholder {
            color: var(--minimal-text-secondary) !important;
        }

        #findbar button,
        #findbar-find-next,
        #findbar-find-previous,
        #findbar-close-button {
            background-color: transparent !important;
            color: var(--minimal-text) !important;
            border-color: transparent !important;
        }

        #findbar button:hover {
            background-color: var(--minimal-border) !important;
        }

        #findbar .found {
            background-color: var(--color-success) !important;
            color: var(--minimal-bg) !important;
        }

        #findbar .notfound {
            background-color: var(--color-error) !important;
            color: var(--minimal-bg) !important;
        }

        /* ========== NOTIFICATION BARS ========== */

        .notification,
        .infobar {
            background-color: var(--minimal-bg-secondary) !important;
            color: var(--minimal-text) !important;
            border-color: var(--minimal-border) !important;
        }

        .notification[type="warning"],
        .infobar[type="warning"] {
            background-color: var(--color-warning) !important;
            color: var(--minimal-bg) !important;
            border-color: var(--minimal-border) !important;
        }

        .notification[type="critical"],
        .infobar[type="critical"],
        .notification[type="error"],
        .infobar[type="error"] {
            background-color: var(--color-error) !important;
            color: var(--minimal-bg) !important;
            border-color: var(--minimal-border) !important;
        }

        .notification button,
        .infobar button {
            background-color: var(--minimal-border) !important;
            color: var(--minimal-text) !important;
            border-color: var(--minimal-text-secondary) !important;
        }

        .notification button:hover,
        .infobar button:hover {
            background-color: var(--minimal-accent) !important;
            color: var(--minimal-bg) !important;
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
            --uc-menu-hover-bg: var(--accent-dim);
            --uc-menu-active-bg: var(--accent-primary);
            --uc-menu-active-fg: var(--minimal-bg);
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
            color: var(--uc-menu-color) !important;
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

        /* Ensure menu items have proper text color in light mode */
        panel richlistitem,
        panel richlistitem label {
            color: var(--uc-menu-color) !important;
        }

        menu:hover,
        menu[_moz-menuactive],
        menu[open],
        menuitem:hover,
        menuitem[_moz-menuactive] {
            background-color: var(--uc-menu-hover-bg) !important;
            color: var(--uc-menu-color) !important;
            transition: background-color 150ms ease !important;
        }

        menu[_moz-menuactive],
        menuitem[_moz-menuactive][selected="true"] {
            background-color: var(--uc-menu-active-bg) !important;
            color: var(--uc-menu-active-fg) !important;
        }

        menu[disabled="true"],
        menuitem[disabled="true"] {
            color: var(--uc-menu-disabled) !important;
            opacity: 0.6 !important;
        }

        /* ========== SIDEBAR STYLING (Fallback if shown) ========== */

        #sidebar,
        #sidebar-box {
            background-color: var(--minimal-bg) !important;
            color: var(--minimal-text) !important;
        }

        #sidebar-box {
            display: none !important;
            visibility: hidden !important;
        }

        #sidebar-splitter {
            display: none !important;
        }

        /* Fallback colors if sidebar becomes visible */
        #sidebar-tree,
        #sidebar-listbox {
            background-color: var(--minimal-bg) !important;
            color: var(--minimal-text) !important;
        }

        #sidebar treeitem,
        #sidebar listitem {
            color: var(--minimal-text) !important;
        }

        /* ========== DIALOGS & MODALS ========== */

        dialog,
        .dialog {
            background-color: var(--minimal-bg) !important;
            color: var(--minimal-text) !important;
            border-color: var(--minimal-border) !important;
        }

        dialog button,
        .dialog button {
            background-color: var(--minimal-bg-secondary) !important;
            color: var(--minimal-text) !important;
            border-color: var(--minimal-border) !important;
        }

        dialog button:hover,
        .dialog button:hover {
            background-color: var(--minimal-border) !important;
        }

        dialog input,
        dialog textarea,
        dialog select,
        .dialog input,
        .dialog textarea,
        .dialog select {
            background-color: var(--minimal-bg) !important;
            color: var(--minimal-text) !important;
            border-color: var(--minimal-border) !important;
        }

        /* ========== GLOBAL INPUT ELEMENTS ========== */

        input[type="text"],
        input[type="password"],
        input[type="email"],
        input[type="url"],
        input[type="number"],
        textarea,
        select {
            background-color: var(--minimal-bg) !important;
            color: var(--minimal-text) !important;
            border-color: var(--minimal-border) !important;
        }

        input::placeholder,
        textarea::placeholder {
            color: var(--minimal-text-secondary) !important;
            opacity: 0.7 !important;
        }

        input:disabled,
        textarea:disabled,
        select:disabled,
        button:disabled {
            color: var(--minimal-text-secondary) !important;
            opacity: 0.6 !important;
        }

        input:focus,
        textarea:focus,
        select:focus {
            outline: 2px solid var(--minimal-accent) !important;
            outline-offset: 1px !important;
            background-color: var(--minimal-bg) !important;
        }

        /* ========== LISTBOX & TREE ELEMENTS ========== */

        listbox,
        tree {
            background-color: var(--minimal-bg) !important;
            color: var(--minimal-text) !important;
        }

        listitem,
        treeitem {
            color: var(--minimal-text) !important;
        }

        listitem[selected],
        treeitem[selected] {
            background-color: var(--minimal-border) !important;
            color: var(--minimal-text) !important;
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

        /* ========== ANOTHER ONELINE THEME ========== */
        /* Based on https://github.com/JarnotMaciej/Essence */

        /* Menu button */
        #PanelUI-button {
            -moz-box-ordinal-group: 0 !important;
            order: -2 !important;
            margin: 2px !important;
            /* display: none !important; */ /* uncomment to hide menu button */
        }

        /* Window control buttons (min, resize and close) */
        .titlebar-buttonbox-container {
            display: none !important;
            margin-right: 12px !important;
        }

        /* Hide home and reload buttons (keep back/forward visible) */
        #home-button,
        #reload-button {
            display: none !important;
        }

        /* Extensions button - visible for 1Password and other extensions */
        /* #unified-extensions-button {
            display: none !important;
        } */

        /* Extension name inside URL bar */
        #identity-box.extensionPage #identity-icon-label {
            visibility: collapse !important;
        }

        /* All tabs (v-like) button */
        #alltabs-button {
            display: none !important;
        }

        /* URL bar icons */
        #identity-permission-box,
        #star-button-box,
        #identity-icon-box,
        #picture-in-picture-button,
        #tracking-protection-icon-container,
        #reader-mode-button,
        #translations-button {
            display: none !important;
        }

        /* "This time search with:..." */
        #urlbar .search-one-offs {
            display: none !important;
        }

        /* Space before and after tabs */
        .titlebar-spacer {
            display: none;
        }

        /* Navbar size calc */
        :root {
            --tab-border-radius: 6px !important;
            --NavbarWidth: 50;
            --TabsHeight: 36;
            --TabsBorder: 8;
            --NavbarHeightSmall: calc(var(--TabsHeight) + var(--TabsBorder));
        }

        @media screen and (min-width:1325px) {
            :root #nav-bar {
                margin-top: calc(var(--TabsHeight) * -1px - var(--TabsBorder) * 1px)!important;
                height: calc(var(--TabsHeight) * 1px + var(--TabsBorder) * 1px);
            }
            #TabsToolbar {
                margin-left: calc(1325px / 100 * var(--NavbarWidth)) !important;
            }
            #nav-bar {
                margin-right: calc(100vw - calc(1325px / 100 * var(--NavbarWidth))) !important;
                vertical-align: center !important;
            }
            #urlbar-container {
                min-width: 0px !important;
                flex: auto !important;
            }
            toolbarspring {
                display: none !important;
            }
        }

        @media screen and (min-width:950px) and (max-width:1324px) {
            :root #nav-bar {
                margin-top: calc(var(--TabsHeight) * -1px - var(--TabsBorder) * 1px) !important;
                height: calc(var(--TabsHeight) * 1px + var(--TabsBorder) * 1px);
            }
            #TabsToolbar {
                margin-left: calc(var(--NavbarWidth) * 1vw) !important;
            }
            #nav-bar {
                margin-right: calc(100vw - calc(var(--NavbarWidth) * 1vw)) !important;
                vertical-align: center !important;
            }
            #urlbar-container {
                min-width: 0px !important;
                flex: auto !important;
            }
            toolbarspring {
                display: none !important;
            }
            #TabsToolbar, #nav-bar {
                transition: margin-top .25s !important;
            }
        }

        @media screen and (max-width:949px) {
            :root #nav-bar {
                padding: 0 5px 0 5px!important;
                height: calc(var(--NavbarHeightSmall) * 1px) !important;
            }
            toolbarspring {
                display: none !important;
            }
            #TabsToolbar, #nav-bar {
                transition: margin-top .25s !important;
            }

        #nav-bar, #PersonalToolbar {
            background-color: var(--minimal-bg) !important;
            background-image: none !important;
            box-shadow: none !important;
        }

        #nav-bar {
            margin-left: 3px;
        }

        .tab-background, .tab-stack {
            min-height: calc(var(--TabsHeight) * 1px) !important;
        }

        /* Removes urlbar border/background */
        #urlbar-background {
            border: none !important;
            outline: none !important;
            transition: .15s !important;
        }

        /* Keep urlbar background visible with theme colors */
        #urlbar:not(:hover):not([breakout][breakout-extend]) > #urlbar-background {
            box-shadow: none !important;
            background: var(--minimal-bg-secondary) !important;
        }

        /* Removes annoying border */
        #navigator-toolbox {
            border: none !important;
        }

        /* Fades window while not in focus */
        #navigator-toolbox-background:-moz-window-inactive {
            filter: contrast(90%);
        }

        /* Fullscreen warning - use semantic colors */
        #fullscreen-warning {
            border: 1px solid var(--minimal-border) !important;
            background: var(--minimal-bg-secondary) !important;
            color: var(--minimal-text) !important;
        }

        #fullscreen-warning button {
            background-color: var(--minimal-border) !important;
            color: var(--minimal-text) !important;
            border-color: var(--minimal-text-secondary) !important;
        }

        #fullscreen-warning button:hover {
            background-color: var(--minimal-accent) !important;
            color: var(--minimal-bg) !important;
        }

        /* Tabs close button */
        .tabbrowser-tab:not(:hover) .tab-close-button {
            opacity: 0% !important;
            transition: 0.3s !important;
            display: -moz-box !important;
        }

        .tab-close-button[selected]:not(:hover) {
            opacity: 45% !important;
            transition: 0.3s !important;
            display: -moz-box !important;
        }

        .tabbrowser-tab:hover .tab-close-button {
            opacity: 50%;
            transition: 0.3s !important;
            background: none !important;
            cursor: pointer;
            display: -moz-box !important;
        }

        .tab-close-button:hover {
            opacity: 100% !important;
            transition: 0.3s !important;
            background: none !important;
            cursor: pointer;
            display: -moz-box !important;
        }

        .tab-close-button[selected]:hover {
            opacity: 100% !important;
            transition: 0.3s !important;
            background: none !important;
            cursor: pointer;
            display: -moz-box !important;
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

        /* ========== TABLISS NEW TAB THEMING ========== */

        @-moz-document url-prefix("moz-extension://") {
          :root {
            --tabliss-bg: var(--minimal-bg) !important;
            --tabliss-fg: var(--minimal-text) !important;
            --tabliss-accent: var(--minimal-accent) !important;
          }

          body {
            background-color: var(--minimal-bg) !important;
            color: var(--minimal-text) !important;
          }

          /* Match toolbar appearance */
          .widgets,
          .toolbar,
          .settings-panel,
          [class*="Widget"],
          [class*="Settings"] {
            background-color: var(--minimal-bg) !important;
            color: var(--minimal-text) !important;
          }

          /* Style Tabliss inputs and buttons */
          input,
          select,
          button {
            background-color: var(--minimal-bg-secondary) !important;
            color: var(--minimal-text) !important;
            border: 1px solid var(--minimal-border) !important;
          }

          button:hover {
            background-color: var(--minimal-border) !important;
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
      semanticColors = utils.createSemanticMapping themeData.palettes.${config.variant};
    in
    {
      inherit (config) variant;
      transparency = config.transparency or (throw "Missing transparency configuration");
      inherit semanticColors;
    };
}
