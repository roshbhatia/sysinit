{
  lib,
  pkgs,
  config,
  ...
}:

let
  themeLib = import ../../shared/theme-colors.nix { inherit lib; };
  themeColors = themeLib.colorsOf config;
  c = themeColors;
  themeConfig = config.sysinit.theme;
  monospaceFont = themeConfig.font.monospace;
  opacity = toString themeConfig.transparency.opacity;
  blur = toString themeConfig.transparency.blur;
  render =
    path: replacements:
    lib.replaceStrings (lib.attrNames replacements) (map (name: replacements.${name}) (
      lib.attrNames replacements
    )) (builtins.readFile path);

  newtabHTML = render ./firefox/newtab.html {
    "@base00@" = c.base00;
  };

  userChromeCSS = render ./firefox/userChrome.css {
    "@base00@" = c.base00;
    "@base01@" = c.base01;
    "@base02@" = c.base02;
    "@base03@" = c.base03;
    "@base04@" = c.base04;
    "@base05@" = c.base05;
    "@base06@" = c.base06;
    "@base08@" = c.base08;
    "@base0A@" = c.base0A;
    "@base0B@" = c.base0B;
    "@base0D@" = c.base0D;
    "@base0E@" = c.base0E;
    "@blur@" = blur;
    "@monospace-font@" = monospaceFont;
    "@opacity@" = opacity;
  };

  userContentCSS = render ./firefox/userContent.css {
    "@base00@" = c.base00;
    "@base01@" = c.base01;
    "@base02@" = c.base02;
    "@base04@" = c.base04;
    "@base05@" = c.base05;
    "@base0D@" = c.base0D;
  };

  tridactylRC = builtins.readFile ./firefox/tridactylrc;

  tridactylThemeCSS = render ./firefox/tridactyl.css {
    "@base00@" = c.base00;
    "@base01@" = c.base01;
    "@base02@" = c.base02;
    "@base03@" = c.base03;
    "@base04@" = c.base04;
    "@base05@" = c.base05;
    "@base0A@" = c.base0A;
    "@base0D@" = c.base0D;
    "@monospace-font@" = monospaceFont;
  };
in
{

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

        # Restore the last session. The default is 1, the homepage, which drops
        # every open tab on a clean quit and keeps the session only after a crash.
        "browser.startup.page" = 3;

        "browser.search.suggest.enabled" = false;
        "browser.urlbar.suggest.searches" = false;
        "browser.urlbar.showSearchSuggestionsFirst" = false;
        "extensions.autoDisableScopes" = 0;
        "extensions.enabledScopes" = 15;
        "browser.uiCustomization.state" = builtins.toJSON {
          placements = {
            "nav-bar" = [
              "back-button"
              "forward-button"
              "urlbar-container"
              "_d634138d-c276-4fc8-924b-40a0ea21d284_-browser-action"
              "PanelUI-button"
            ];
            "TabsToolbar" = [
              "tabbrowser-tabs"
              "new-tab-button"
            ];
            "unified-extensions-area" = [
              "uBlock0_raymondhill_net-browser-action"
              "tridactyl_vim_cmcaine_co_uk-browser-action"
              "jid1-BoFifL9Vbdl2zQ_jetpack-browser-action"
              "_testpilot-containers-browser-action"
              "sponsorBlocker_ajay_app-browser-action"
              "_4cfbf13b-f27f-4f03-91dc-2aa17644029a_-browser-action"
            ];
            "widget-overflow-fixed-list" = [ ];
            "toolbar-menubar" = [ "menubar-items" ];
          };
          seen = [
            "_d634138d-c276-4fc8-924b-40a0ea21d284_-browser-action"
            "addon_darkreader_org-browser-action"
            "uBlock0_raymondhill_net-browser-action"
            "tridactyl_vim_cmcaine_co_uk-browser-action"
            "jid1-BoFifL9Vbdl2zQ_jetpack-browser-action"
            "_testpilot-containers-browser-action"
            "sponsorBlocker_ajay_app-browser-action"
            "_4cfbf13b-f27f-4f03-91dc-2aa17644029a_-browser-action"
            "developer-button"
          ];
          dirtyAreaCache = [
            "nav-bar"
            "TabsToolbar"
            "unified-extensions-area"
          ];
          currentVersion = 20;
          newElementCount = 0;
        };
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
      DisableFirefoxAccounts = true;
      DisableAccounts = true;
      DisableFirefoxScreenshots = true;
      DontCheckDefaultBrowser = true;
      NewTabURL = "file://${config.home.homeDirectory}/.local/share/firefox/newtab.html";
      HomepageURL = "file://${config.home.homeDirectory}/.local/share/firefox/newtab.html";
      DisplayBookmarksToolbar = "never";
      DisplayMenuBar = "default-off";
      SearchBar = "unified";
      SearchEngines = {
        Default = "Google";
        PreventInstalls = true;
      };
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
        "{d634138d-c276-4fc8-924b-40a0ea21d284}" = {
          installation_mode = "force_installed";
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/1password-x-password-manager/latest.xpi";
          default_area = "navbar";
        };
      };
    };
  };

  xdg.configFile = {
    "tridactyl/tridactylrc".text = tridactylRC;
    "tridactyl/themes/stylix.css".text = tridactylThemeCSS;
  };

  home.file.".local/share/firefox/newtab.html".text = newtabHTML;
}
