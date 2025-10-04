{
  pkgs,
  values,
  lib,
  ...
}:

let
  themeSystem = import ../../../lib/theme { inherit lib; };

  themeConfig = {
    colorscheme = values.theme.colorscheme;
    variant = values.theme.variant;
    presets = [ ];
    transparency = values.theme.transparency;
  };

  firefoxTheme = themeSystem.createAppConfig "firefox" themeConfig { };

  userChromeCSS = pkgs.writeText "userChrome.css" firefoxTheme.userChromeCSS;

  userContentCSS = pkgs.writeText "userContent.css" firefoxTheme.userContentCSS;
in
{
  # Use home.file for macOS Firefox installed via Homebrew
  home.file = {
    "Library/Application Support/Firefox/Profiles/default/chrome/userChrome.css" = {
      source = userChromeCSS;
    };
    "Library/Application Support/Firefox/Profiles/default/chrome/userContent.css" = {
      source = userContentCSS;
    };
    "Library/Application Support/Firefox/Profiles/default/chrome/brave-icons/BackButton.svg" = {
      source = ./chrome-theme/brave-icons/BackButton.svg;
    };
    "Library/Application Support/Firefox/Profiles/default/chrome/brave-icons/Bookmark.svg" = {
      source = ./chrome-theme/brave-icons/Bookmark.svg;
    };
    "Library/Application Support/Firefox/Profiles/default/chrome/brave-icons/BookmarkFilled.svg" = {
      source = ./chrome-theme/brave-icons/BookmarkFilled.svg;
    };
    "Library/Application Support/Firefox/Profiles/default/chrome/brave-icons/CloseTab.svg" = {
      source = ./chrome-theme/brave-icons/CloseTab.svg;
    };
    "Library/Application Support/Firefox/Profiles/default/chrome/brave-icons/ForwardButton.svg" = {
      source = ./chrome-theme/brave-icons/ForwardButton.svg;
    };
    "Library/Application Support/Firefox/Profiles/default/chrome/brave-icons/Lock.svg" = {
      source = ./chrome-theme/brave-icons/Lock.svg;
    };
    "Library/Application Support/Firefox/Profiles/default/chrome/brave-icons/Menu.svg" = {
      source = ./chrome-theme/brave-icons/Menu.svg;
    };
    "Library/Application Support/Firefox/Profiles/default/chrome/brave-icons/NewTab.svg" = {
      source = ./chrome-theme/brave-icons/NewTab.svg;
    };
    "Library/Application Support/Firefox/Profiles/default/chrome/brave-icons/Plugins.svg" = {
      source = ./chrome-theme/brave-icons/Plugins.svg;
    };
    "Library/Application Support/Firefox/Profiles/default/chrome/brave-icons/Reload.svg" = {
      source = ./chrome-theme/brave-icons/Reload.svg;
    };
    "Library/Application Support/Firefox/Profiles/default/chrome/brave-icons/Search.svg" = {
      source = ./chrome-theme/brave-icons/Search.svg;
    };
    "Library/Application Support/Firefox/Profiles/default/chrome/brave-icons/Warning.svg" = {
      source = ./chrome-theme/brave-icons/Warning.svg;
    };
    "Library/Application Support/Firefox/Profiles/default/chrome/brave-icons/folder-locked-symbolic.svg" =
      {
        source = ./chrome-theme/brave-icons/folder-locked-symbolic.svg;
      };
    "Library/Application Support/Firefox/Profiles/default/chrome/brave-icons/tracking-protection-animatable.svg" =
      {
        source = ./chrome-theme/brave-icons/tracking-protection-animatable.svg;
      };
    "Library/Application Support/Firefox/Profiles/default/chrome/brave-icons/tracking-protection.svg" =
      {
        source = ./chrome-theme/brave-icons/tracking-protection.svg;
      };
    "Library/Application Support/Firefox/Profiles/default/chrome/brave-icons/view-refresh-symbolic.svg" =
      {
        source = ./chrome-theme/brave-icons/view-refresh-symbolic.svg;
      };
  };

  xdg.configFile = {
    "tridactyl/tridactylrc" = {
      text = ''
        " Tridactyl Configuration for Arc-Inspired Minimal Firefox
        " Tab fuzzy finding: Press 'b' or use :buffer to search tabs

        " Better tab search - case insensitive fuzzy finding
        set tabopencontaineraware true
        set tabsort mru

        " Minimal UI hints
        set hintchars asdfghjkl
        set hintfiltermode vimperator-reflow
        set hintuppercase false

        " ========== SMOOTH SCROLLING ==========

        " Enable smooth scrolling
        set smoothscroll true
        set scrollduration 150

        " Smooth scroll with j/k (Arc-style)
        bind j scrollline 4
        bind k scrollline -4

        " Faster scrolling with Shift
        bind <C-d> scrollpage 0.5
        bind <C-u> scrollpage -0.5

        " Top and bottom
        bind gg scrollto 0
        bind G scrollto 100

        " ========== TAB MANAGEMENT ==========

        " Quick tab switching with 'b' command (fuzzy search)
        " Usage: Press 'b' then type any part of tab title/URL
        bind b fillcmdline buffer

        " Navigate tabs (using uppercase to avoid conflict with scrolling)
        bind J tabprev
        bind K tabnext
        bind gT tabprev
        bind gt tabnext

        " Close tab
        bind x tabclose
        bind d tabclose

        " Restore closed tab
        bind X undo
        bind u undo

        " New tab
        bind t tabnew

        " Move tabs
        bind < tabmove -1
        bind > tabmove +1

        " ========== NAVIGATION ==========

        " History navigation
        bind H back
        bind L forward

        " ========== SEARCH ==========

        " Search with current search engine
        bind s fillcmdline open search
        bind S fillcmdline tabopen search

        " Find mode
        bind / fillcmdline find
        bind ? fillcmdline find -?
        bind n findnext 1
        bind N findnext -1

        " ========== VISUAL & THEME ==========

        " Theme integration - minimal UI
        colors dark

        " Don't show mode indicator (cleaner UI)
        set modeindicatorshowkeys false

        " ========== MISC ==========

        " Performance - lazy load
        set allowautofocus false

        " Disable annoying behaviors
        set newtabfocus page

        " Quick marks for common pages
        " Usage: go<key> to open, gn<key> to open in new tab
        " Example: gog opens Google

        " Ignore mode for certain sites (if you prefer default Firefox behavior)
        " autocmd DocStart ^http(s?)://mail.google.com enterIgnoreMode

        " ========== HINTS & SELECTION ==========

        " Follow hints
        bind f hint
        bind F hint -b

        " Yank (copy)
        bind yy clipboard yank
        bind yt clipboard tabopen
        bind yl clipboard yank canonical

        " Open in new tab
        bind O fillcmdline tabopen
        bind o fillcmdline open
      '';
    };
  };

  programs.firefox = {
    enable = true;
    package = null;

    profiles = {
      default = {
        name = "default";
        isDefault = true;
        extensions = {
          packages = with pkgs.nur.repos.rycee.firefox-addons; [
            ublock-origin
            onepassword-password-manager
            reddit-enhancement-suite
            old-reddit-redirect
            multi-account-containers
            tridactyl
          ];
        };

        settings = {
          # Disable search suggestions for cleaner UI
          "browser.search.suggest.enabled" = false;
          "browser.urlbar.suggest.searches" = false;
          "browser.urlbar.showSearchSuggestionsFirst" = false;

          # New tab page - minimal
          "browser.newtabpage.activity-stream.showSearch" = true;
          "browser.newtabpage.activity-stream.showTopSites" = false;
          "browser.newtabpage.activity-stream.feeds.topsites" = false;
          "browser.newtabpage.activity-stream.feeds.section.topstories" = false;
          "browser.newtabpage.activity-stream.feeds.section.highlights" = false;

          # Enable custom CSS
          "toolkit.legacyUserProfileCustomizations.stylesheets" = true;

          # Enable modern rendering features for blur and transparency
          "layout.css.backdrop-filter.enabled" = true;
          "gfx.webrender.all" = true;
          "svg.context-properties.content.enabled" = true;

          # Compact mode for minimal aesthetic
          "browser.compactmode.show" = true;
          "browser.uidensity" = 1; # 0=normal, 1=compact, 2=touch

          # Smooth scrolling
          "general.smoothScroll" = true;
          "general.smoothScroll.msdPhysics.enabled" = true;

          # Hide tab manager menu button (cleaner tab bar)
          "browser.tabs.tabmanager.enabled" = false;

          # Minimal animations
          "ui.prefersReducedMotion" = 0; # Enable smooth animations

          # Color management for better theming
          "layout.css.color-mix.enabled" = true;
          "layout.css.has-selector.enabled" = true;
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

            "Nix Home Manager " = {
              urls = [
                {
                  template = "https://mynixos.com/home-manager/options/programs";
                  params = [
                    {
                      name = "query";
                      value = "{searchTerms}";
                    }
                  ];
                }
              ];
              icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
              definedAliases = [ "@nhm" ];
            };
          }
          // values.firefox.searchEngines;
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
      OverrideFirstRunPage = "";
      OverridePostUpdatePage = "";
      DontCheckDefaultBrowser = true;
      DisplayBookmarksToolbar = "never";
      DisplayMenuBar = "default-off";
      SearchBar = "unified";
    };
  };
}
