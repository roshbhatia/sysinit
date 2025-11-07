{
  pkgs,
  values,
  utils,
  ...
}:

let
  inherit (utils.themes) createAppConfig;

  # Pass entire theme config to enable appearance-to-variant derivation
  # Note: using 'or' pattern to provide defaults for optional fields
  themeConfig = values.theme // {
    presets = values.theme.presets or [ ];
    overrides = values.theme.overrides or { };
  };

  firefoxTheme = createAppConfig "firefox" themeConfig { };

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
in
{
  programs.firefox = {
    enable = true;
    package = firefoxWrapper // {
      override = _args: firefoxWrapper;
    };

    profiles.default = {
      id = 0;
      isDefault = true;
      name = "default";

      userChrome = firefoxTheme.userChromeCSS or "";
      userContent = firefoxTheme.userContentCSS or "";

      extensions.packages = with pkgs.firefox-addons; [
        ublock-origin
        # onepassword-password-manager  # Removed due to unfree license - install manually from 1Password.com
        reddit-enhancement-suite
        old-reddit-redirect
        multi-account-containers
        vimium
        sponsorblock
        decentraleyes
        tabliss
      ];

      settings = {
        "toolkit.legacyUserProfileCustomizations.stylesheets" = true;

        # Theme appearance settings - sync with system theme
        "ui.systemUsesDarkTheme" = if values.theme.appearance == "dark" then 1 else 0;
        "browser.theme.content-theme" = if values.theme.appearance == "dark" then 0 else 1;
        "browser.theme.toolbar-theme" = if values.theme.appearance == "dark" then 0 else 1;
        "layout.css.prefers-color-scheme.content-override" =
          if values.theme.appearance == "dark" then 0 else 1;

        "browser.newtabpage.activity-stream.enabled" = false;

        "browser.search.suggest.enabled" = false;
        "browser.urlbar.suggest.searches" = false;
        "browser.urlbar.showSearchSuggestionsFirst" = false;
        "browser.newtabpage.activity-stream.showSearch" = false;
        "browser.newtabpage.activity-stream.showTopSites" = false;
        "browser.newtabpage.activity-stream.feeds.topsites" = false;
        "browser.newtabpage.activity-stream.feeds.section.topstories" = false;
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
    };
  };
}
