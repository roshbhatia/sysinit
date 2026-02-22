{
  pkgs,
  utils,
  config,
  ...
}:

let
  themeLib = utils.theme;

  # macOS Firefox wrapper - /Applications is macOS-specific hardcoded path
  # This is acceptable here because this entire module is macOS-only (in modules/darwin/home/)
  # For future NixOS support, create a separate module with different wrapper
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

  # Access stylix colors
  colors = config.lib.stylix.colors;

  # Map base16 colors to semantic names for Firefox
  semanticColors = {
    background = {
      primary = "#${colors.base00}";
      secondary = "#${colors.base01}";
      tertiary = "#${colors.base02}";
      overlay = "#${colors.base01}";
    };
    foreground = {
      primary = "#${colors.base05}";
      secondary = "#${colors.base04}";
      muted = "#${colors.base03}";
      subtle = "#${colors.base03}";
    };
    accent = {
      primary = "#${colors.base0D}";
      secondary = "#${colors.base0C}";
      tertiary = "#${colors.base0E}";
      dim = "#${colors.base02}";
    };
    semantic = {
      error = "#${colors.base08}";
      warning = "#${colors.base0A}";
      success = "#${colors.base0B}";
      info = "#${colors.base0D}";
    };
    syntax = {
      keyword = "#${colors.base0E}";
      string = "#${colors.base0B}";
      number = "#${colors.base09}";
      comment = "#${colors.base03}";
      function = "#${colors.base0D}";
      variable = "#${colors.base08}";
      type = "#${colors.base0A}";
      operator = "#${colors.base05}";
      constant = "#${colors.base09}";
      builtin = "#${colors.base0C}";
    };
  };

  # Generate custom config with stylix colors
  themeConfigWithColors = config.sysinit.theme // {
    semanticColors = semanticColors;
  };

  # Generate Firefox CSS using stylix colors
  firefoxConfig = themeLib.adapters.firefox.createFirefoxConfig { } themeConfigWithColors { };
in
{
  stylix.targets."nixos-icons".enable = true;

  # Disable stylix firefox target to use custom CSS
  stylix.targets.firefox.enable = false;

  programs.firefox = {
    enable = true;
    package = firefoxWrapper // {
      override = _args: firefoxWrapper;
    };

    profiles.default = {
      id = 0;
      isDefault = true;
      name = "default";

      # Custom CSS with stylix colors
      userChrome = firefoxConfig.userChromeCSS or "";
      userContent = firefoxConfig.userContentCSS or "";

      extensions.packages = with pkgs.firefox-addons; [
        decentraleyes
        multi-account-containers
        multi-split-view
        old-reddit-redirect
        reddit-enhancement-suite
        refined-github-
        sponsorblock
        tabliss
        ublock-origin
        ultimadark
        vimium
        web-clipper-obsidian
      ];

      settings = {
        "toolkit.legacyUserProfileCustomizations.stylesheets" = true;

        # Theme appearance settings - let custom CSS drive the UI
        # ui.systemUsesDarkTheme: 0=light, 1=dark, 2=auto
        # Using 2 (auto) allows custom CSS to override while respecting system preference
        "ui.systemUsesDarkTheme" = 2;

        # Content theme: 0=dark, 1=light, 2=auto (follows content scheme preference)
        "browser.theme.content-theme" = 2;

        # Toolbar theme: 0=dark, 1=light, 2=auto
        "browser.theme.toolbar-theme" = 2;

        # CSS color scheme override: 0=auto, 1=light, 2=dark
        # Using 0 (auto) lets media queries and CSS vars handle appearance
        "layout.css.prefers-color-scheme.content-override" = 0;
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
