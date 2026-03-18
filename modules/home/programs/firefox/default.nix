{
  pkgs,
  config,
  ...
}:

let
  c = config.lib.stylix.colors;
  themeConfig = config.sysinit.theme;
  monospaceFont = themeConfig.font.monospace;
  opacity = toString themeConfig.transparency.opacity;
  blur = toString themeConfig.transparency.blur;
  newtabPath = "${config.xdg.configHome}/tridactyl/newtab.html";

  userChromeCSS = ''
    /* ========== BASE16 THEME VARIABLES (from Stylix) ========== */
    :root {
      --bg: #${c.base00};
      --bg-alt: #${c.base01};
      --bg-sel: #${c.base02};
      --fg-muted: #${c.base03};
      --fg-dim: #${c.base04};
      --fg: #${c.base05};
      --fg-bright: #${c.base06};
      --accent: #${c.base0D};
      --accent-alt: #${c.base0E};
      --error: #${c.base08};
      --warning: #${c.base0A};
      --success: #${c.base0B};
      --info: #${c.base0D};

      --opacity: ${opacity};
      --blur-amount: ${blur}px;
      --tab-border-radius: 6px !important;
      --uc-autohide-navbar-delay: 600ms;
    }

    /* ========== TYPOGRAPHY ========== */
    * {
      font-family: "${monospaceFont}", -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif !important;
    }

    /* ========== TOOLBAR ========== */
    #navigator-toolbox {
      background-color: var(--bg) !important;
      border: 0px !important;
    }

    #navigator-toolbox::after {
      display: none !important;
    }

    :root {
      --toolbox-border-bottom-color: transparent !important;
    }

    toolbar .toolbarbutton-1 {
      -moz-appearance: none !important;
      appearance: none !important;
      margin: -1px;
      padding: 4px var(--toolbarbutton-outer-padding) 0 !important;
      -moz-box-pack: center;
    }

    #nav-bar .toolbarbutton-1 {
      padding-top: 6px !important;
    }

    toolbar .toolbarbutton-1,
    toolbar .toolbarbutton-text {
      color: var(--fg) !important;
    }

    toolbar .toolbarbutton-1:hover {
      background-color: var(--bg-sel) !important;
      color: var(--fg) !important;
    }

    toolbar .toolbarbutton-1[open],
    toolbar .toolbarbutton-1[checked],
    toolbar .toolbarbutton-1:active {
      background-color: var(--accent) !important;
      color: var(--bg) !important;
    }

    toolbar .toolbarbutton-1:focus-visible {
      outline: 2px solid var(--accent) !important;
      outline-offset: 1px !important;
    }

    /* ========== WINDOW CONTROLS ========== */
    .titlebar-buttonbox-container { display: none !important; }
    .titlebar-placeholder[type="pre-tabs"] { display: none !important; }
    .titlebar-spacer { display: none; }

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
      background: var(--bg) !important;
    }

    #urlbar-background {
      background: var(--bg-alt) !important;
    }

    .tab-label {
      -moz-box-flex: 1 !important;
      text-align: center !important;
      font-size: 10px !important;
      color: var(--fg-dim) !important;
      transition: color 150ms ease !important;
    }

    .tabbrowser-tab:not([selected]) .tab-label {
      color: var(--fg-dim) !important;
    }

    .tabbrowser-tab:not([selected]):hover .tab-label {
      color: var(--fg) !important;
    }

    #TabsToolbar .tabbrowser-tab[selected] .tab-label {
      color: var(--fg) !important;
      font-weight: bold !important;
      font-size: 10px !important;
    }

    .tabbrowser-tab[selected] {
      background-color: var(--bg-alt) !important;
      border-bottom: 2px solid var(--accent) !important;
    }

    .tabbrowser-tab:not([pinned]):not(:hover) .tab-close-button {
      visibility: collapse !important;
    }

    .tabbrowser-tab:not([pinned]):hover .tab-close-button {
      visibility: visible !important;
      display: block !important;
    }

    /* ========== SCROLLBAR ========== */
    scrollbar {
      -moz-appearance: none !important;
      background: transparent !important;
      width: 0px !important;
    }

    * {
      scrollbar-width: thin !important;
      scrollbar-color: var(--fg-dim) transparent !important;
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
      background: var(--bg-alt) !important;
      border: 1px solid var(--bg-sel) !important;
      border-radius: 4px !important;
      transition: border-color 150ms ease !important;
    }

    #urlbar:focus-within > #urlbar-background {
      border-color: var(--accent) !important;
      box-shadow: 0 0 0 2px var(--bg) !important;
    }

    :root {
      --lwt-toolbar-field-background-color: var(--bg-alt) !important;
      --lwt-toolbar-field-border-color: var(--bg-sel) !important;
      --toolbar-bgcolor: var(--bg) !important;
      --toolbar-field-background-color: var(--bg-alt) !important;
      --toolbar-field-focus-background-color: var(--bg-alt) !important;
      --toolbar-field-focus-border-color: var(--accent) !important;
    }

    #page-action-buttons { display: none !important; }

    #urlbar .urlbar-input,
    #urlbar .urlbar-input-box input {
      color: var(--fg) !important;
      caret-color: var(--accent) !important;
    }

    #urlbar .urlbar-input::selection {
      background-color: var(--accent) !important;
      color: var(--bg) !important;
    }

    #urlbar-results { background-color: var(--bg-alt) !important; }

    .urlbarView-row {
      background-color: var(--bg-alt) !important;
      color: var(--fg) !important;
    }

    .urlbarView-row:hover,
    .urlbarView-row[selected] {
      background-color: var(--bg-sel) !important;
      color: var(--fg) !important;
    }

    .urlbarView-title,
    .urlbarView-action { color: var(--fg) !important; }
    .urlbarView-url { color: var(--fg-dim) !important; }

    .urlbar-input-box > .urlbar-input::placeholder { opacity: 0 !important; }

    /* ========== HIDE CLUTTER ========== */
    #identity-box.extensionPage #identity-icon-labels,
    #identity-box.extensionPage #identity-icon-label {
      visibility: collapse !important;
    }
    #tracking-protection-icon-container { visibility: collapse !important; }
    #identity-icon { visibility: visible !important; }
    #home-button, #reload-button { display: none !important; }
    #alltabs-button { display: none !important; }
    #identity-permission-box,
    #star-button-box,
    #identity-icon-box,
    #picture-in-picture-button,
    #reader-mode-button,
    #translations-button { display: none !important; }
    #urlbar .search-one-offs { display: none !important; }

    .bookmark-item > .toolbarbutton-icon { display: none !important; }

    /* ========== FIND BAR ========== */
    #findbar {
      background-color: var(--bg-alt) !important;
      color: var(--fg) !important;
      border-color: var(--bg-sel) !important;
    }

    #findbar-textbox, #findbar input {
      background-color: var(--bg) !important;
      color: var(--fg) !important;
      border-color: var(--bg-sel) !important;
    }

    #findbar button:hover { background-color: var(--bg-sel) !important; }
    #findbar .found { background-color: var(--success) !important; color: var(--bg) !important; }
    #findbar .notfound { background-color: var(--error) !important; color: var(--bg) !important; }

    /* ========== CONTEXT MENUS ========== */
    menupopup,
    #main-menubar > menu > menupopup,
    #context-navigation {
      color: var(--fg) !important;
      padding: 2px !important;
      background-color: var(--bg-alt) !important;
      border-color: var(--fg-dim) !important;
      border-radius: 4px !important;
    }

    menulist, menuitem, menu {
      min-height: 1.8em !important;
      color: var(--fg) !important;
      -moz-appearance: none !important;
    }

    menu:hover, menu[_moz-menuactive], menuitem:hover, menuitem[_moz-menuactive] {
      background-color: var(--bg-sel) !important;
      color: var(--fg) !important;
    }

    menu[disabled="true"], menuitem[disabled="true"] {
      color: var(--fg-dim) !important;
      opacity: 0.6 !important;
    }

    /* ========== NOTIFICATIONS ========== */
    .notification, .infobar {
      background-color: var(--bg-alt) !important;
      color: var(--fg) !important;
    }

    /* ========== TOOLTIPS ========== */
    tooltip {
      -moz-appearance: none !important;
      color: var(--fg) !important;
      background-color: var(--bg-alt) !important;
      padding: 6px !important;
      border-radius: 4px !important;
      box-shadow: none !important;
    }

    /* ========== CONTENT AREA ========== */
    .browserContainer { background-color: var(--bg) !important; }

    /* ========== NAVBAR AUTO-HIDE ========== */
    #nav-bar {
      min-height: 0 !important;
      max-height: 0 !important;
      overflow: hidden !important;
      opacity: 0 !important;
      transition: max-height 150ms ease var(--uc-autohide-navbar-delay),
                  opacity 150ms ease var(--uc-autohide-navbar-delay) !important;
    }

    #navigator-toolbox:hover > #nav-bar,
    #nav-bar:focus-within,
    #navigator-toolbox:has([open]) > #nav-bar {
      max-height: 40px !important;
      overflow: visible !important;
      opacity: 1 !important;
      transition-delay: 0ms !important;
    }
  '';

  userContentCSS = ''
    :root {
      --bg: #${c.base00};
      --bg-alt: #${c.base01};
      --fg: #${c.base05};
      --fg-dim: #${c.base04};
      --accent: #${c.base0D};
      --border: #${c.base02};
    }

    @-moz-document url-prefix(about:home), url-prefix(about:newtab) {
      body { background: var(--bg) !important; color: var(--fg) !important; }
    }

    @-moz-document url-prefix("moz-extension://") {
      body { background-color: var(--bg) !important; color: var(--fg) !important; }
      input, select, button {
        background-color: var(--bg-alt) !important;
        color: var(--fg) !important;
        border: 1px solid var(--border) !important;
      }
      button:hover { background-color: var(--border) !important; }
    }
  '';

  tridactylRC = ''
    " Tridactyl configuration — qutebrowser-like Firefox

    " Theme
    colors everforest

    " New tab page
    set newtab file://${newtabPath}

    " Smooth scrolling
    set smoothscroll true

    " Search engines (mirror Firefox search config)
    set searchengine google
    set searchurls.np https://search.nixos.org/packages?type=packages&query=%s
    set searchurls.no https://search.nixos.org/options?channel=unstable&query=%s
    set searchurls.gh https://github.com/search?q=%s

    " Qutebrowser-style tab navigation
    bind J tabnext
    bind K tabprev

    " Disable on sites that need full keyboard
    blacklistadd mail.google.com
  '';

  tridactylThemeCSS = ''
    /* Tridactyl Everforest Theme — generated from Stylix Base16 */

    :root .TridactylOwnNamespace {
      --tridactyl-font-family: "${monospaceFont}", monospace;
      --tridactyl-font-family-mono: "${monospaceFont}", monospace;
      --tridactyl-font-size: 12px;
      --tridactyl-small-font-size: 10px;

      /* Command line */
      --tridactyl-cmdl-bg: #${c.base01};
      --tridactyl-cmdl-fg: #${c.base05};

      /* General */
      --tridactyl-bg: #${c.base00};
      --tridactyl-fg: #${c.base05};
      --tridactyl-url-bg: transparent;
      --tridactyl-url-fg: #${c.base0D};
      --tridactyl-highlight-box-bg: #${c.base01};
      --tridactyl-highlight-box-fg: #${c.base05};
      --tridactyl-of-fg: #${c.base04};

      /* Completions */
      --tridactyl-cmplt-bg: #${c.base00};
      --tridactyl-cmplt-fg: #${c.base05};
      --tridactyl-cmplt-border-top: 1px solid #${c.base02};
      --tridactyl-header-first-bg: #${c.base02};
      --tridactyl-header-bg: #${c.base02};
      --tridactyl-header-fg: #${c.base05};
      --tridactyl-header-border-bottom: 1px solid #${c.base01};
      --tridactyl-option-focused-bg: #${c.base0D};
      --tridactyl-option-focused-fg: #${c.base00};

      /* Hints */
      --tridactyl-hintspan-font-family: "${monospaceFont}", monospace;
      --tridactyl-hintspan-font-size: 11px;
      --tridactyl-hintspan-font-weight: bold;
      --tridactyl-hintspan-fg: #${c.base00};
      --tridactyl-hintspan-bg: #${c.base0A};
      --tridactyl-hintspan-border: 1px solid #${c.base03};
    }
  '';

  newtabHTML = ''
    <!DOCTYPE html>
    <html lang="en">
    <head>
      <meta charset="utf-8">
      <title>New Tab</title>
      <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
          background: #${c.base00};
          color: #${c.base05};
          font-family: "${monospaceFont}", monospace;
          height: 100vh;
          display: flex;
          align-items: center;
          justify-content: center;
          text-align: center;
          padding: 2rem;
        }
        #quote {
          max-width: 700px;
          font-size: 1.2rem;
          line-height: 1.8;
        }
        #quote .time {
          font-weight: bold;
          color: #${c.base0D};
        }
        #meta {
          margin-top: 1.5rem;
          color: #${c.base04};
          font-size: 0.9rem;
          font-style: italic;
        }
        #fallback {
          font-size: 3rem;
          color: #${c.base04};
          font-weight: 300;
        }
      </style>
    </head>
    <body>
      <div id="container">
        <div id="quote"></div>
        <div id="meta"></div>
        <div id="fallback"></div>
      </div>
      <script>
        var currentMinute = null;

        function pad(n) {
          return n < 10 ? "0" + n : "" + n;
        }

        function fetchQuote() {
          var now = new Date();
          var hh = pad(now.getHours());
          var mm = pad(now.getMinutes());
          var key = hh + ":" + mm;

          if (key === currentMinute) return;
          currentMinute = key;

          var url = "https://raw.githubusercontent.com/lbngoc/literature-clock/master/docs/times/" + hh + ":" + mm + ".json";

          fetch(url)
            .then(function(r) { return r.json(); })
            .then(function(quotes) {
              var q = quotes[Math.floor(Math.random() * quotes.length)];
              document.getElementById("quote").innerHTML =
                (q.quote_first || "") +
                '<span class="time">' + (q.quote_time_case || "") + "</span>" +
                (q.quote_last || "");
              document.getElementById("meta").textContent =
                "— " + (q.author || "Unknown") + ", " + (q.title || "Unknown");
              document.getElementById("fallback").textContent = "";
            })
            .catch(function() {
              document.getElementById("quote").innerHTML = "";
              document.getElementById("meta").textContent = "";
              document.getElementById("fallback").textContent = hh + ":" + mm;
            });
        }

        fetchQuote();
        setInterval(fetchQuote, 1000);
      </script>
    </body>
    </html>
  '';

in
{
  stylix.targets.firefox.enable = false;

  programs.firefox = {
    enable = true;
    nativeMessagingHosts = [ pkgs.tridactyl-native ];

    profiles.default = {
      id = 0;
      isDefault = true;
      name = "default";

      userChrome = userChromeCSS;
      userContent = userContentCSS;

      extensions.packages = with pkgs.firefox-addons; [
        darkreader
        decentraleyes
        multi-account-containers
        old-reddit-redirect
        reddit-enhancement-suite
        refined-github
        sponsorblock
        tridactyl
        ublock-origin
        web-clipper-obsidian
      ];

      settings = {
        "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
        "ui.systemUsesDarkTheme" = 2;
        "browser.theme.content-theme" = 2;
        "browser.theme.toolbar-theme" = 2;
        "layout.css.prefers-color-scheme.content-override" = 0;
        "browser.newtabpage.activity-stream.enabled" = false;
        "browser.search.suggest.enabled" = false;
        "browser.urlbar.suggest.searches" = false;
        "browser.urlbar.showSearchSuggestionsFirst" = false;
        "browser.newtabpage.activity-stream.showSearch" = false;
        "browser.newtabpage.activity-stream.showTopSites" = false;
        "browser.newtabpage.activity-stream.feeds.topsites" = false;
        "browser.newtabpage.activity-stream.feeds.section.topstories" = false;
        "browser.startup.homepage" = "file://${newtabPath}";
        "extensions.autoDisableScopes" = 0;
        "extensions.enabledScopes" = 15;
      };

      search = {
        force = true;
        default = "google";
        engines = {
          "Nix Packages" = {
            urls = [
              {
                template = "https://search.nixos.org/packages";
                params = [
                  {
                    name = "type";
                    value = "packages";
                  }
                  {
                    name = "query";
                    value = "{searchTerms}";
                  }
                ];
              }
            ];
            icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
            definedAliases = [ "@np" ];
          };

          "Nix Options" = {
            urls = [
              {
                template = "https://search.nixos.org/options";
                params = [
                  {
                    name = "channel";
                    value = "unstable";
                  }
                  {
                    name = "from";
                    value = "0";
                  }
                  {
                    name = "size";
                    value = "50";
                  }
                  {
                    name = "sort";
                    value = "relevance";
                  }
                  {
                    name = "type";
                    value = "packages";
                  }
                  {
                    name = "query";
                    value = "{searchTerms}";
                  }
                ];
              }
            ];
            icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
            definedAliases = [ "@no" ];
          };

          "GitHub" = {
            urls = [
              {
                template = "https://github.com/search";
                params = [
                  {
                    name = "q";
                    value = "{searchTerms}";
                  }
                ];
              }
            ];
            icon = "https://github.com/favicon.ico";
            updateInterval = 24 * 60 * 60 * 1000;
            definedAliases = [ "@gh" ];
          };
        };
      };
    };

    policies = {
      DisableTelemetry = true;
      DisableFirefoxStudies = true;
      EnableTrackingProtection = {
        Value = true;
        Locked = true;
        Cryptomining = true;
        Fingerprinting = true;
      };
      DisablePocket = true;
      DisableFirefoxAccounts = false;
      DisableAccounts = false;
      DisableFirefoxScreenshots = true;
      DontCheckDefaultBrowser = true;
      DisplayBookmarksToolbar = "never";
      DisplayMenuBar = "default-off";
      SearchBar = "unified";
      ExtensionSettings = {
        "tridactyl.vim@cmcaine.co.uk" = {
          installation_mode = "force_installed";
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/tridactyl-vim/latest.xpi";
        };
        "addon@darkreader.org" = {
          installation_mode = "force_installed";
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/darkreader/latest.xpi";
        };
        "jid1-BoFifL9Vbdl2zQ@jetpack" = {
          installation_mode = "force_installed";
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/decentraleyes/latest.xpi";
        };
        "@testpilot-containers" = {
          installation_mode = "force_installed";
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/multi-account-containers/latest.xpi";
        };
        "{9063c2e9-e07c-4c2c-9646-cfe7ca8d0498}" = {
          installation_mode = "force_installed";
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/old-reddit-redirect/latest.xpi";
        };
        "jid1-xUfzOsOFlzSOXg@jetpack" = {
          installation_mode = "force_installed";
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/reddit-enhancement-suite/latest.xpi";
        };
        "{a4c4eda4-fb84-4a84-b4a1-f7c1cbf2a1ad}" = {
          installation_mode = "force_installed";
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/refined-github-/latest.xpi";
        };
        "sponsorBlocker@ajay.app" = {
          installation_mode = "force_installed";
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/sponsorblock/latest.xpi";
        };
        "uBlock0@raymondhill.net" = {
          installation_mode = "force_installed";
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
        };
        "{4cfbf13b-f27f-4f03-91dc-2aa17644029a}" = {
          installation_mode = "force_installed";
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/obsidian-web-clipper/latest.xpi";
        };
      };
    };
  };

  xdg.configFile = {
    "tridactyl/tridactylrc".text = tridactylRC;
    "tridactyl/themes/everforest.css".text = tridactylThemeCSS;
    "tridactyl/newtab.html".text = newtabHTML;
  };
}
