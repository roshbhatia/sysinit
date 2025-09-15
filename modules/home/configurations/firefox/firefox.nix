{
  pkgs,
  values,
  lib,
  ...
}:

let
  firefoxWrapper =
    pkgs.runCommand "firefox-homebrew-wrapper"
      {
        pname = "firefox";
        version = "homebrew";
      }
      ''
        mkdir -p $out/bin
        cat > $out/bin/firefox <<EOF
        #!/bin/sh
        exec /Applications/Firefox.app/Contents/MacOS/firefox "\$@"
        EOF
        chmod +x $out/bin/firefox
      '';

  # Import theme system
  themeSystem = import ../../lib/theme { inherit lib; };

  # Create theme config from values
  themeConfig = {
    colorscheme = values.theme.colorscheme or "catppuccin";
    variant = values.theme.variant or "macchiato";
    transparency = values.theme.transparency or {
      enable = true;
      opacity = 0.85;
      blur = 10;
    };
  };

  # Generate Firefox theme using theme system
  firefoxTheme = themeSystem.createAppConfig "firefox" themeConfig {
    stretchedTabs = values.firefox.theme.stretchedTabs or false;
  };

  # Generate userChrome.css with semantic theming and optional stretched tabs
  userChromeCSS =
    let
      baseCSS = builtins.readFile ./chrome-theme/userChrome.css;
      stretchedTabsCSS = if (values.firefox.theme.stretchedTabs or false) then ''
        /* Stretched tabs configuration */
        #urlbar-background {
            border: none !important;
        }

        /* Stretch Tabs */
        .tabbrowser-tab[fadein]:not([pinned]) {
            max-width: none !important;
        }
      '' else "";
    in
    pkgs.writeText "userChrome.css" (firefoxTheme.userChromeCSS + baseCSS + stretchedTabsCSS);

  # Use userContent.css from theme system
  userContentCSS = pkgs.writeText "userContent.css" firefoxTheme.userContentCSS;
in
{
  programs.firefox = {
    enable = true;
    package = firefoxWrapper // {
      pname = "firefox";
      meta = {
        description = "Firefox browser (macOS Application)";
        platforms = lib.platforms.darwin;
      };
    };

    profiles = {
      default = {
        name = "default";
        isDefault = true;
        extensions = with pkgs.nur.repos.rycee.firefox-addons; [
          ublock-origin
          multi-account-containers
          tridactyl
        ];

        settings = {
          "browser.search.suggest.enabled" = false;
          "browser.urlbar.suggest.searches" = false;
          "browser.urlbar.showSearchSuggestionsFirst" = false;
          "browser.newtabpage.activity-stream.showSearch" = true;
          "browser.newtabpage.activity-stream.showTopSites" = false;
          "browser.newtabpage.activity-stream.feeds.topsites" = false;
          "browser.newtabpage.activity-stream.feeds.section.topstories" = false;

          # Enable custom CSS
          "toolkit.legacyUserProfileCustomizations.stylesheets" = true;

          # GlassFox theme optimizations
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
          } // (values.firefox.searchEngines or { });
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

    # GlassFox theme with semantic colors (no wallpapers needed)
    chrome = {
      "userChrome.css" = {
        source = userChromeCSS;
      };
      "userContent.css" = {
        source = userContentCSS;
      };
      "brave-icons/BackButton.svg" = {
        source = ./chrome-theme/brave-icons/BackButton.svg;
      };
      "brave-icons/Bookmark.svg" = {
        source = ./chrome-theme/brave-icons/Bookmark.svg;
      };
      "brave-icons/BookmarkFilled.svg" = {
        source = ./chrome-theme/brave-icons/BookmarkFilled.svg;
      };
      "brave-icons/CloseTab.svg" = {
        source = ./chrome-theme/brave-icons/CloseTab.svg;
      };
      "brave-icons/ForwardButton.svg" = {
        source = ./chrome-theme/brave-icons/ForwardButton.svg;
      };
      "brave-icons/Lock.svg" = {
        source = ./chrome-theme/brave-icons/Lock.svg;
      };
      "brave-icons/Menu.svg" = {
        source = ./chrome-theme/brave-icons/Menu.svg;
      };
      "brave-icons/NewTab.svg" = {
        source = ./chrome-theme/brave-icons/NewTab.svg;
      };
      "brave-icons/Plugins.svg" = {
        source = ./chrome-theme/brave-icons/Plugins.svg;
      };
      "brave-icons/Reload.svg" = {
        source = ./chrome-theme/brave-icons/Reload.svg;
      };
      "brave-icons/Search.svg" = {
        source = ./chrome-theme/brave-icons/Search.svg;
      };
      "brave-icons/Warning.svg" = {
        source = ./chrome-theme/brave-icons/Warning.svg;
      };
      "brave-icons/folder-locked-symbolic.svg" = {
        source = ./chrome-theme/brave-icons/folder-locked-symbolic.svg;
      };
      "brave-icons/tracking-protection-animatable.svg" = {
        source = ./chrome-theme/brave-icons/tracking-protection-animatable.svg;
      };
      "brave-icons/tracking-protection.svg" = {
        source = ./chrome-theme/brave-icons/tracking-protection.svg;
      };
      "brave-icons/view-refresh-symbolic.svg" = {
        source = ./chrome-theme/brave-icons/view-refresh-symbolic.svg;
      };
    };
  };
}
