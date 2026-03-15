# Shared Firefox configuration — extensions, policies, search engines, theming
# Imported on both Darwin and NixOS. Platform-specific package/wrapper
# is set by the caller (darwin sets homebrew wrapper, NixOS uses pkgs.firefox).
{
  pkgs,
  config,
  lib,
  utils,
  ...
}:

let
  colors = config.lib.stylix.colors;

  themeLib = utils.theme;

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

  themeConfigWithColors = config.sysinit.theme // {
    inherit semanticColors;
  };

  firefoxConfig = themeLib.adapters.firefox.createFirefoxConfig { } themeConfigWithColors { };

  isDarwin = pkgs.stdenv.isDarwin;
in
{
  stylix.targets.firefox.enable = false;

  programs.firefox = {
    enable = true;

    # Package is set platform-specifically:
    # - Darwin: homebrew wrapper (set in modules/darwin/home/firefox.nix)
    # - NixOS: pkgs.firefox (default, no override needed here)

    profiles.default = {
      id = 0;
      isDefault = true;
      name = "default";

      userChrome = firefoxConfig.userChromeCSS or "";
      userContent = firefoxConfig.userContentCSS or "";

      extensions.packages = with pkgs.firefox-addons; [
        decentraleyes
        multi-account-containers
        old-reddit-redirect
        reddit-enhancement-suite
        refined-github
        sponsorblock
        tabliss
        ublock-origin
        vimium
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
                  { name = "type"; value = "packages"; }
                  { name = "query"; value = "{searchTerms}"; }
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
                  { name = "channel"; value = "unstable"; }
                  { name = "from"; value = "0"; }
                  { name = "size"; value = "50"; }
                  { name = "sort"; value = "relevance"; }
                  { name = "type"; value = "packages"; }
                  { name = "query"; value = "{searchTerms}"; }
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
                  { name = "q"; value = "{searchTerms}"; }
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
