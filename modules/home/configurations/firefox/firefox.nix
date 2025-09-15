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

  firefoxTheme = themeSystem.createAppConfig "firefox" themeConfig {
    stretchedTabs = values.firefox.theme.stretchedTabs or false;
  };

  userChromeCSS =
    let
      stretchedTabsCSS =
        if values.firefox.theme.stretchedTabs or false then
          ''
            /* Stretched tabs configuration */
            #urlbar-background {
                border: none !important;
            }

            /* Stretch Tabs */
            .tabbrowser-tab[fadein]:not([pinned]) {
                max-width: none !important;
            }
          ''
        else
          "";
    in
    pkgs.writeText "userChrome.css" (firefoxTheme.userChromeCSS + stretchedTabsCSS);

  userContentCSS = pkgs.writeText "userContent.css" firefoxTheme.userContentCSS;
in
{
  xdg.configFile = {
    "firefox/default/chrome/userChrome.css" = {
      source = userChromeCSS;
    };
    "firefox/default/chrome/userContent.css" = {
      source = userContentCSS;
    };
    "firefox/default/chrome/brave-icons/BackButton.svg" = {
      source = ./chrome-theme/brave-icons/BackButton.svg;
    };
    "firefox/default/chrome/brave-icons/Bookmark.svg" = {
      source = ./chrome-theme/brave-icons/Bookmark.svg;
    };
    "firefox/default/chrome/brave-icons/BookmarkFilled.svg" = {
      source = ./chrome-theme/brave-icons/BookmarkFilled.svg;
    };
    "firefox/default/chrome/brave-icons/CloseTab.svg" = {
      source = ./chrome-theme/brave-icons/CloseTab.svg;
    };
    "firefox/default/chrome/brave-icons/ForwardButton.svg" = {
      source = ./chrome-theme/brave-icons/ForwardButton.svg;
    };
    "firefox/default/chrome/brave-icons/Lock.svg" = {
      source = ./chrome-theme/brave-icons/Lock.svg;
    };
    "firefox/default/chrome/brave-icons/Menu.svg" = {
      source = ./chrome-theme/brave-icons/Menu.svg;
    };
    "firefox/default/chrome/brave-icons/NewTab.svg" = {
      source = ./chrome-theme/brave-icons/NewTab.svg;
    };
    "firefox/default/chrome/brave-icons/Plugins.svg" = {
      source = ./chrome-theme/brave-icons/Plugins.svg;
    };
    "firefox/default/chrome/brave-icons/Reload.svg" = {
      source = ./chrome-theme/brave-icons/Reload.svg;
    };
    "firefox/default/chrome/brave-icons/Search.svg" = {
      source = ./chrome-theme/brave-icons/Search.svg;
    };
    "firefox/default/chrome/brave-icons/Warning.svg" = {
      source = ./chrome-theme/brave-icons/Warning.svg;
    };
    "firefox/default/chrome/brave-icons/folder-locked-symbolic.svg" = {
      source = ./chrome-theme/brave-icons/folder-locked-symbolic.svg;
    };
    "firefox/default/chrome/brave-icons/tracking-protection-animatable.svg" = {
      source = ./chrome-theme/brave-icons/tracking-protection-animatable.svg;
    };
    "firefox/default/chrome/brave-icons/tracking-protection.svg" = {
      source = ./chrome-theme/brave-icons/tracking-protection.svg;
    };
    "firefox/default/chrome/brave-icons/view-refresh-symbolic.svg" = {
      source = ./chrome-theme/brave-icons/view-refresh-symbolic.svg;
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
          "browser.search.suggest.enabled" = false;
          "browser.urlbar.suggest.searches" = false;
          "browser.urlbar.showSearchSuggestionsFirst" = false;
          "browser.newtabpage.activity-stream.showSearch" = true;
          "browser.newtabpage.activity-stream.showTopSites" = false;
          "browser.newtabpage.activity-stream.feeds.topsites" = false;
          "browser.newtabpage.activity-stream.feeds.section.topstories" = false;

          "toolkit.legacyUserProfileCustomizations.stylesheets" = true;

          "layout.css.backdrop-filter.enabled" = true;
          "gfx.webrender.all" = true;
          "svg.context-properties.content.enabled" = true;
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
          }
          // (values.firefox.searchEngines or { });
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
