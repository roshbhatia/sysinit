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
        Arc Browser-Inspired Firefox Theme
        The Browser Company aesthetic with transparency, blur, and square tabs
        --------------------------------------------------------------------------------- */

        /* ========== TYPOGRAPHY ========== */

        * {
            font-family: "TX-02", -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif !important;
        }

        /* ========== CORE TRANSPARENCY & BLUR ========== */

        :root#main-window {
            background-color: transparent !important;
        }

        :root {
            --arc-transparency: ${toString (transparency.opacity * 0.5)};
            --arc-blur: ${toString (transparency.blur * 1.5)}px;
            --arc-sidebar-width: 0px;
        }

        :root #TabsToolbar,
        :root #titlebar,
        :root #tabbrowser-tabs,
        :root #PersonalToolbar,
        :root #nav-bar,
        :root #browser,
        :root #navigator-toolbox {
            -moz-default-appearance: none !important;
            appearance: none !important;
            background-color: transparent !important;
        }

        :root:not(:-moz-window-inactive) #navigator-toolbox {
            background-color: transparent !important;
            backdrop-filter: blur(var(--arc-blur)) saturate(2) !important;
        }

        /* ========== ARC-STYLE TOOLBAR ========== */

        #TabsToolbar {
            background: color-mix(in srgb, var(--bg-primary) calc(var(--arc-transparency) * 100%), transparent) !important;
            backdrop-filter: blur(var(--arc-blur)) saturate(2.2) !important;
            padding-block: 8px !important;
            padding-inline: 12px !important;
            border: none !important;
            box-shadow: inset 0 -1px 0 0 color-mix(in srgb, var(--accent-dim) 15%, transparent) !important;
        }

        #nav-bar {
            background: color-mix(in srgb, var(--bg-secondary) calc(var(--arc-transparency) * 80%), transparent) !important;
            backdrop-filter: blur(calc(var(--arc-blur) * 0.9)) saturate(2) !important;
            border: none !important;
            box-shadow: none !important;
            padding-block: 12px !important;
            padding-inline: 16px !important;
        }

        #navigator-toolbox {
            border: none !important;
            background: linear-gradient(
                180deg,
                color-mix(in srgb, var(--bg-primary) calc(var(--arc-transparency) * 100%), transparent) 0%,
                color-mix(in srgb, var(--bg-secondary) calc(var(--arc-transparency) * 80%), transparent) 50%,
                transparent 100%
            ) !important;
        }

        /* ========== ARC-STYLE SQUARE TABS ========== */

        /* Remove all tab borders and separators */
        .tabbrowser-tab::after,
        .tabbrowser-tab::before {
            display: none !important;
        }

        /* Square tab container */
        .tabbrowser-tab {
            min-width: 0px !important;
            max-width: 200px !important;
            padding-inline: 3px !important;
            margin-inline-end: 2px !important;
        }

        /* Square tabs with top rounded corners (Arc style) */
        .tab-background {
            border: none !important;
            box-shadow: none !important;
            border-radius: 8px 8px 0 0 !important;
            margin-block: 0px !important;
            margin-bottom: -1px !important;
            transition: all 0.15s cubic-bezier(0.2, 0, 0, 1) !important;
            position: relative !important;
        }

        /* Inactive tabs - glass morphism effect */
        .tab-background:not([selected]) {
            background: color-mix(in srgb, var(--bg-overlay) 20%, transparent) !important;
            backdrop-filter: blur(calc(var(--arc-blur) * 0.3)) !important;
        }

        .tabbrowser-tab:not([selected]):hover .tab-background {
            background: color-mix(in srgb, var(--bg-overlay) 45%, transparent) !important;
            backdrop-filter: blur(calc(var(--arc-blur) * 0.5)) !important;
            transform: translateY(-1px) !important;
        }

        /* Active tab - Arc-style elevation and glow */
        .tab-background[selected],
        .tab-background[multiselected="true"] {
            background: color-mix(in srgb, var(--bg-secondary) 90%, transparent) !important;
            backdrop-filter: blur(var(--arc-blur)) saturate(1.5) !important;
            box-shadow:
                0 0 0 1px color-mix(in srgb, var(--accent-secondary) 40%, transparent),
                0 2px 12px color-mix(in srgb, var(--accent-primary) 12%, transparent),
                inset 0 1px 0 0 color-mix(in srgb, var(--accent-primary) 20%, transparent) !important;
            transform: translateY(0px) !important;
        }

        /* Tab content - Arc spacing */
        .tab-content {
            overflow: hidden !important;
            padding-inline: 12px !important;
            padding-block: 8px !important;
        }

        /* Tab labels - Arc typography */
        .tab-label {
            color: var(--text-secondary) !important;
            font-weight: 450 !important;
            font-size: 12.5px !important;
            letter-spacing: -0.01em !important;
            transition: color 0.15s ease !important;
        }

        .tab-background[selected] .tab-label {
            color: var(--text-primary) !important;
            font-weight: 550 !important;
        }

        /* Tab favicon - subtle glow on active */
        .tab-icon-image {
            transition: all 0.15s ease !important;
        }

        .tab-background[selected] .tab-icon-image {
            filter: drop-shadow(0 0 4px color-mix(in srgb, var(--accent-primary) 30%, transparent)) !important;
        }

        /* Tab close button - Arc style */
        .tabbrowser-tab:not([pinned]) .tab-close-button {
            display: -moz-box !important;
            opacity: 0 !important;
            visibility: collapse !important;
            transition: opacity 0.15s ease, visibility 0.15s ease, background 0.15s ease !important;
            list-style-image: url("./brave-icons/CloseTab.svg") !important;
            width: 18px !important;
            height: 18px !important;
            margin: 0 !important;
            padding: 3px !important;
            border-radius: 4px !important;
        }

        .tabbrowser-tab:not([pinned]):hover .tab-close-button,
        .tab-background[selected] .tab-close-button {
            opacity: 0.6 !important;
            visibility: visible !important;
        }

        .tabbrowser-tab:not([pinned]) .tab-close-button:hover {
            opacity: 1 !important;
            background: color-mix(in srgb, var(--accent-dim) 70%, transparent) !important;
            transform: scale(1.05) !important;
        }

        /* Remove tab separators */
        .titlebar-spacer[type="pre-tabs"] {
            border: none !important;
        }

        .titlebar-spacer[type="post-tabs"] {
            border: none !important;
        }

        /* ========== ARC-STYLE FLOATING COMMAND BAR ========== */

        #urlbar-container {
            max-width: 60% !important;
            margin: 0 auto !important;
        }

        #urlbar {
            border: none !important;
            min-height: 38px !important;
        }

        /* Floating command bar with heavy blur */
        #urlbar-background {
            background: color-mix(in srgb, var(--bg-secondary) 75%, transparent) !important;
            border: 1px solid color-mix(in srgb, var(--accent-dim) 30%, transparent) !important;
            border-radius: 10px !important;
            backdrop-filter: blur(var(--arc-blur)) saturate(1.8) !important;
            box-shadow:
                0 2px 16px color-mix(in srgb, var(--bg-primary) 5%, transparent),
                0 0 0 0.5px color-mix(in srgb, var(--accent-secondary) 10%, transparent),
                inset 0 1px 0 0 color-mix(in srgb, var(--accent-primary) 8%, transparent) !important;
            outline: none !important;
            transition: all 0.2s cubic-bezier(0.2, 0, 0, 1) !important;
        }

        /* URL bar on hover - Arc glow effect */
        #urlbar:hover > #urlbar-background {
            background: color-mix(in srgb, var(--bg-secondary) 85%, transparent) !important;
            border-color: color-mix(in srgb, var(--accent-secondary) 50%, transparent) !important;
            box-shadow:
                0 4px 24px color-mix(in srgb, var(--accent-primary) 8%, transparent),
                0 0 0 0.5px color-mix(in srgb, var(--accent-secondary) 20%, transparent),
                inset 0 1px 0 0 color-mix(in srgb, var(--accent-primary) 12%, transparent) !important;
            transform: translateY(-1px) !important;
        }

        /* URL bar on focus - Arc active state */
        #urlbar[focused] > #urlbar-background {
            background: color-mix(in srgb, var(--bg-secondary) 95%, transparent) !important;
            border-color: var(--accent-primary) !important;
            box-shadow:
                0 8px 32px color-mix(in srgb, var(--accent-primary) 15%, transparent),
                0 0 0 1px var(--accent-primary),
                inset 0 1px 0 0 color-mix(in srgb, var(--accent-primary) 20%, transparent) !important;
            transform: translateY(-2px) scale(1.01) !important;
        }

        /* URL bar dropdown - Arc style */
        #urlbar[breakout][breakout-extend] > #urlbar-background {
            background: color-mix(in srgb, var(--bg-secondary) 98%, transparent) !important;
            border-color: var(--accent-primary) !important;
        }

        #urlbar[open] > .urlbarView > .urlbarView-body-outer > .urlbarView-body-inner {
            border-top: none !important;
        }

        /* Dropdown results - Arc glass effect */
        .urlbarView {
            background: color-mix(in srgb, var(--bg-secondary) 95%, transparent) !important;
            backdrop-filter: blur(var(--arc-blur)) saturate(1.5) !important;
            border-radius: 0 0 10px 10px !important;
            border: 1px solid var(--accent-primary) !important;
            border-top: none !important;
            margin-inline: 0 !important;
        }

        .urlbarView-row {
            background: transparent !important;
            border-radius: 6px !important;
            transition: background 0.15s ease !important;
        }

        .urlbarView-row:hover {
            background: color-mix(in srgb, var(--accent-dim) 40%, transparent) !important;
        }

        .urlbarView-row[selected] {
            background: color-mix(in srgb, var(--accent-secondary) 30%, transparent) !important;
        }

        /* Center URL text (Arc command bar style) */
        #urlbar-input {
            text-align: center !important;
            color: var(--text-primary) !important;
            font-size: 13px !important;
            font-weight: 450 !important;
            transition: text-align 0.2s ease !important;
        }

        #urlbar[focused] #urlbar-input {
            text-align: left !important;
        }

        /* URL bar placeholder */
        #urlbar-input::placeholder {
            color: var(--text-muted) !important;
            opacity: 0.6 !important;
        }

        /* ========== ARC-STYLE CONTENT AREA ========== */

        #appcontent {
            margin-top: 0px !important;
            margin-inline: 0px !important;
            margin-block-end: 0px !important;
            border-radius: 12px 12px 0 0 !important;
            border: 1px solid color-mix(in srgb, var(--accent-dim) 20%, transparent) !important;
            border-bottom: none !important;
            overflow: hidden !important;
            box-shadow:
                0 -2px 24px color-mix(in srgb, var(--bg-primary) 10%, transparent),
                inset 0 1px 0 0 color-mix(in srgb, var(--accent-secondary) 8%, transparent) !important;
        }

        /* ========== ARC-STYLE TOOLBAR BUTTONS ========== */

        :root, toolbar {
            --toolbarbutton-hover-background: color-mix(in srgb, var(--accent-dim) 50%, transparent) !important;
            --toolbarbutton-active-background: color-mix(in srgb, var(--accent-dim) 70%, transparent) !important;
            --toolbarbutton-border-radius: 7px !important;
        }

        .toolbarbutton-1 {
            fill: var(--text-secondary) !important;
            border-radius: var(--toolbarbutton-border-radius) !important;
            transition: all 0.15s cubic-bezier(0.2, 0, 0, 1) !important;
            padding: 6px !important;
        }

        .toolbarbutton-1:hover {
            fill: var(--text-primary) !important;
            background: var(--toolbarbutton-hover-background) !important;
            transform: scale(1.05) !important;
        }

        .toolbarbutton-1:active {
            background: var(--toolbarbutton-active-background) !important;
            transform: scale(0.98) !important;
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

        /* ========== ARC CLEAN AESTHETIC ========== */

        /* Completely hide bookmarks toolbar - Arc doesn't show it */
        #PersonalToolbar {
            display: none !important;
            visibility: collapse !important;
        }

        /* Hide tab manager button - cleaner look */
        #alltabs-button {
            display: none !important;
        }

        /* Hide new tab button in tab bar - use Cmd+T instead */
        #tabs-newtab-button {
            display: none !important;
        }

        /* Minimal scrollbar for tab overflow */
        .scrollbutton-up,
        .scrollbutton-down {
            opacity: 0 !important;
            transition: opacity 0.15s ease !important;
        }

        #tabbrowser-tabs:hover .scrollbutton-up,
        #tabbrowser-tabs:hover .scrollbutton-down {
            opacity: 0.5 !important;
        }

        /* ========== ARC ANIMATIONS ========== */

        * {
            transition-timing-function: cubic-bezier(0.2, 0, 0, 1) !important;
        }

        /* Smooth tab animations */
        .tabbrowser-tab {
            transition: all 0.15s cubic-bezier(0.2, 0, 0, 1) !important;
        }

        /* Smooth toolbar transitions */
        #nav-bar, #TabsToolbar {
            transition: all 0.2s cubic-bezier(0.2, 0, 0, 1) !important;
        }

        /* ========== CONTEXT MENUS & POPUPS ========== */

        /* Arc-style context menus */
        menupopup,
        panel {
            background: color-mix(in srgb, var(--bg-secondary) 95%, transparent) !important;
            backdrop-filter: blur(var(--arc-blur)) saturate(1.5) !important;
            border: 1px solid color-mix(in srgb, var(--accent-secondary) 30%, transparent) !important;
            border-radius: 10px !important;
            box-shadow:
                0 8px 32px color-mix(in srgb, var(--bg-primary) 20%, transparent),
                0 0 0 0.5px color-mix(in srgb, var(--accent-primary) 10%, transparent) !important;
            padding: 4px !important;
        }

        menuitem,
        menu {
            background: transparent !important;
            border-radius: 6px !important;
            transition: background 0.15s ease !important;
            margin: 1px 0 !important;
        }

        menuitem:hover,
        menu:hover {
            background: color-mix(in srgb, var(--accent-dim) 50%, transparent) !important;
        }

        menuitem[_moz-menuactive="true"],
        menu[_moz-menuactive="true"] {
            background: color-mix(in srgb, var(--accent-secondary) 40%, transparent) !important;
        }

        /* ========== NOTIFICATION & ALERTS ========== */

        .notificationbox-stack,
        notification {
            background: color-mix(in srgb, var(--bg-secondary) 90%, transparent) !important;
            backdrop-filter: blur(var(--arc-blur)) !important;
            border-radius: 8px !important;
        }

        /* ========== COMPACT MODE REFINEMENTS ========== */

        :root[uidensity="compact"] #TabsToolbar {
            padding-block: 6px !important;
        }

        :root[uidensity="compact"] #nav-bar {
            padding-block: 10px !important;
        }

        :root[uidensity="compact"] .tab-content {
            padding-inline: 10px !important;
            padding-block: 6px !important;
        }

        /* ========== WINDOW CONTROLS (macOS) ========== */

        /* Style window controls to match Arc */
        .titlebar-buttonbox-container {
            margin-left: 8px !important;
        }

        /* ========== SIDEBAR (if enabled) ========== */

        #sidebar-box {
            background: color-mix(in srgb, var(--bg-primary) 95%, transparent) !important;
            backdrop-filter: blur(var(--arc-blur)) saturate(1.5) !important;
            border-right: 1px solid color-mix(in srgb, var(--accent-dim) 20%, transparent) !important;
        }

        #sidebar-header {
            background: color-mix(in srgb, var(--bg-secondary) 90%, transparent) !important;
            border-bottom: 1px solid color-mix(in srgb, var(--accent-dim) 20%, transparent) !important;
        }

        /* ========== FINDBAR ========== */

        .findbar-container {
            background: color-mix(in srgb, var(--bg-secondary) 95%, transparent) !important;
            backdrop-filter: blur(var(--arc-blur)) !important;
            border: 1px solid color-mix(in srgb, var(--accent-dim) 30%, transparent) !important;
            border-radius: 8px !important;
        }

        /* ========== FINAL POLISH ========== */

        /* Remove any remaining visual noise */
        #navigator-toolbox::after {
            display: none !important;
        }

        .titlebar-spacer {
            background: transparent !important;
        }

        /* Ensure smooth rendering */
        * {
            -moz-font-smoothing: antialiased !important;
            -webkit-font-smoothing: antialiased !important;
        }
      '';

      baseUserContentCSS = ''
        /* Arc-Inspired New Tab & Content Pages */

        /* Enhanced Arc-style background gradients */
        @media (prefers-color-scheme: light) {
          :root {
            --background-wallpaper:
              radial-gradient(circle at 20% 30%, color-mix(in srgb, var(--accent-primary) 8%, transparent) 0%, transparent 50%),
              radial-gradient(circle at 80% 70%, color-mix(in srgb, var(--accent-secondary) 6%, transparent) 0%, transparent 50%),
              linear-gradient(135deg,
                var(--bg-primary) 0%,
                color-mix(in srgb, var(--bg-primary) 95%, var(--accent-dim) 5%) 50%,
                var(--bg-secondary) 100%);
          }
        }

        @media (prefers-color-scheme: dark) {
          :root {
            --background-wallpaper:
              radial-gradient(circle at 20% 30%, color-mix(in srgb, var(--accent-primary) 12%, transparent) 0%, transparent 50%),
              radial-gradient(circle at 80% 70%, color-mix(in srgb, var(--accent-secondary) 10%, transparent) 0%, transparent 50%),
              linear-gradient(135deg,
                var(--bg-primary) 0%,
                color-mix(in srgb, var(--bg-primary) 92%, var(--accent-primary) 8%) 30%,
                color-mix(in srgb, var(--bg-secondary) 94%, var(--accent-secondary) 6%) 70%,
                var(--bg-tertiary) 100%);
          }
        }

        @-moz-document url-prefix(about:home), url-prefix(about:newtab) {
          * {
            font-family: "TX-02", -apple-system, BlinkMacSystemFont, sans-serif !important;
          }

          body {
            background: var(--background-wallpaper) !important;
            background-attachment: fixed !important;
            color: var(--text-primary) !important;
          }

          /* Arc-style search bar */
          .search-wrapper {
            background: transparent !important;
            border-radius: 14px !important;
          }

          .search-handoff-button {
            background: color-mix(in srgb, var(--bg-secondary) 80%, transparent) !important;
            backdrop-filter: blur(var(--blur-amount)) saturate(1.5) !important;
            border: 1px solid color-mix(in srgb, var(--accent-dim) 30%, transparent) !important;
            color: var(--text-primary) !important;
            border-radius: 12px !important;
            padding: 16px 20px !important;
            font-size: 14px !important;
            font-weight: 450 !important;
            box-shadow:
              0 4px 20px color-mix(in srgb, var(--bg-primary) 8%, transparent),
              inset 0 1px 0 0 color-mix(in srgb, var(--accent-primary) 10%, transparent) !important;
            transition: all 0.2s cubic-bezier(0.2, 0, 0, 1) !important;
          }

          .search-handoff-button:hover {
            background: color-mix(in srgb, var(--bg-secondary) 90%, transparent) !important;
            border-color: color-mix(in srgb, var(--accent-secondary) 50%, transparent) !important;
            transform: translateY(-2px) scale(1.01) !important;
            box-shadow:
              0 8px 32px color-mix(in srgb, var(--accent-primary) 12%, transparent),
              inset 0 1px 0 0 color-mix(in srgb, var(--accent-primary) 15%, transparent) !important;
          }

          /* Arc-style top sites */
          .top-site-outer {
            background: color-mix(in srgb, var(--bg-overlay) 70%, transparent) !important;
            backdrop-filter: blur(calc(var(--blur-amount) * 0.8)) saturate(1.3) !important;
            border: 1px solid color-mix(in srgb, var(--accent-dim) 20%, transparent) !important;
            border-radius: 10px !important;
            box-shadow: 0 2px 12px color-mix(in srgb, var(--bg-primary) 5%, transparent) !important;
            transition: all 0.2s cubic-bezier(0.2, 0, 0, 1) !important;
          }

          .top-site-outer:hover {
            background: color-mix(in srgb, var(--bg-overlay) 85%, transparent) !important;
            border-color: color-mix(in srgb, var(--accent-secondary) 40%, transparent) !important;
            transform: translateY(-3px) scale(1.02) !important;
            box-shadow:
              0 8px 24px color-mix(in srgb, var(--accent-primary) 10%, transparent),
              inset 0 1px 0 0 color-mix(in srgb, var(--accent-primary) 12%, transparent) !important;
          }

          .top-site-outer .tile {
            background: transparent !important;
          }

          .top-site-icon {
            background: transparent !important;
            filter: drop-shadow(0 0 6px color-mix(in srgb, var(--accent-primary) 15%, transparent)) !important;
          }

          /* Arc-style menus and context elements */
          .customize-menu, .context-menu {
            background: color-mix(in srgb, var(--bg-secondary) 95%, transparent) !important;
            backdrop-filter: blur(var(--blur-amount)) saturate(1.5) !important;
            border: 1px solid color-mix(in srgb, var(--accent-secondary) 30%, transparent) !important;
            border-radius: 10px !important;
            box-shadow:
              0 12px 40px color-mix(in srgb, var(--bg-primary) 15%, transparent),
              0 0 0 0.5px color-mix(in srgb, var(--accent-primary) 10%, transparent) !important;
            padding: 4px !important;
          }

          .context-menu-item {
            border-radius: 6px !important;
            transition: all 0.15s ease !important;
          }

          .context-menu-item:hover {
            background: color-mix(in srgb, var(--accent-secondary) 40%, transparent) !important;
            color: var(--text-primary) !important;
          }

          /* Customize interface elements */
          .customize-item {
            background: color-mix(in srgb, var(--bg-overlay) 70%, transparent) !important;
            backdrop-filter: blur(calc(var(--blur-amount) * 0.5)) !important;
            border-radius: 8px !important;
            border: 1px solid color-mix(in srgb, var(--accent-dim) 25%, transparent) !important;
            transition: all 0.15s ease !important;
          }

          .customize-item:hover {
            border-color: color-mix(in srgb, var(--accent-secondary) 50%, transparent) !important;
            background: color-mix(in srgb, var(--bg-overlay) 85%, transparent) !important;
            transform: scale(1.02) !important;
          }

          /* Activity stream cards - Arc glassmorphism */
          .ds-card {
            background: color-mix(in srgb, var(--bg-overlay) 75%, transparent) !important;
            backdrop-filter: blur(var(--blur-amount)) saturate(1.4) !important;
            border: 1px solid color-mix(in srgb, var(--accent-dim) 25%, transparent) !important;
            border-radius: 10px !important;
            box-shadow: 0 4px 16px color-mix(in srgb, var(--bg-primary) 6%, transparent) !important;
            transition: all 0.2s ease !important;
          }

          .ds-card:hover {
            border-color: color-mix(in srgb, var(--accent-secondary) 45%, transparent) !important;
            background: color-mix(in srgb, var(--bg-overlay) 90%, transparent) !important;
            transform: translateY(-2px) !important;
            box-shadow:
              0 8px 28px color-mix(in srgb, var(--accent-primary) 8%, transparent),
              inset 0 1px 0 0 color-mix(in srgb, var(--accent-primary) 10%, transparent) !important;
          }

          /* Hide unnecessary elements for cleaner Arc look */
          .prefs-button,
          .context-menu-button {
            opacity: 0.6 !important;
            transition: opacity 0.15s ease !important;
          }

          .prefs-button:hover,
          .context-menu-button:hover {
            opacity: 1 !important;
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
