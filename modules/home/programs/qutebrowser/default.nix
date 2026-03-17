# Shared qutebrowser configuration — settings, keybindings, search engines, userscripts
# Imported on both Darwin and NixOS. Stylix auto-themes via built-in target.
{
  pkgs,
  config,
  lib,
  ...
}:

let
  isDarwin = pkgs.stdenv.isDarwin;
  isLinux = pkgs.stdenv.isLinux;

  # Widevine CDM path for DRM content (NixOS only)
  widevinePath = if isLinux then "${pkgs.widevine-cdm}/share/google/chrome/WidevineCdm" else null;

  # Userscript: spoof Chrome UA for the current domain, then reload
  chromeUaSpoof = pkgs.writeShellScript "qute-chrome-ua" ''
    DOMAIN=$(echo "$QUTE_URL" | ${pkgs.coreutils}/bin/cut -d/ -f3)
    CHROME_UA="Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0.0.0 Safari/537.36"
    echo "set -u *://*.$DOMAIN/* content.headers.user_agent '$CHROME_UA'" > "$QUTE_FIFO"
    echo "message-info 'Spoofed Chrome UA for $DOMAIN'" >> "$QUTE_FIFO"
    echo "reload" >> "$QUTE_FIFO"
  '';

in
{
  programs.qutebrowser = {
    enable = true;

    settings = {
      # Privacy
      content.cookies.accept = "no-3rdparty";
      content.webrtc_ip_handling_policy = "default-public-interface-only";
      content.canvas_reading = true;
      content.geolocation = "ask";
      content.notifications.enabled = "ask";
      content.pdfjs = true;

      # Ad blocking
      content.blocking.enabled = true;
      content.blocking.method = "adblock";
      content.blocking.adblock.lists = [
        "https://easylist.to/easylist/easylist.txt"
        "https://easylist.to/easylist/easyprivacy.txt"
        "https://raw.githubusercontent.com/uBlockOrigin/uAssets/master/filters/filters.txt"
        "https://raw.githubusercontent.com/uBlockOrigin/uAssets/master/filters/annoyances.txt"
        "https://raw.githubusercontent.com/uBlockOrigin/uAssets/master/filters/badware.txt"
        "https://raw.githubusercontent.com/uBlockOrigin/uAssets/master/filters/privacy.txt"
        "https://raw.githubusercontent.com/uBlockOrigin/uAssets/master/filters/resource-abuse.txt"
        "https://pgl.yoyo.org/adservers/serverlist.php?hostformat=hosts&showintro=0&mimetype=plaintext"
      ];

      # URL handling — dns-only means "localhost:8080" goes to localhost, not a search
      url.default_page = "https://www.google.com";
      url.start_pages = [ "https://www.google.com" ];
      url.auto_search = "naive";

      # Tab behavior
      tabs.position = "top";
      tabs.show = "multiple";
      tabs.last_close = "default-page";
      tabs.new_position.related = "next";
      tabs.new_position.unrelated = "last";
      tabs.background = true;
      tabs.title.format = "{audio}{current_title}";
      tabs.favicons.show = "always";
      tabs.close_mouse_button = "middle";
      tabs.mousewheel_switching = false;
      tabs.select_on_remove = "last-used";

      # Window title
      window.title_format = "{perc}{current_title}{title_sep}qutebrowser";

      # Completion
      completion.shrink = true;
      completion.use_best_match = false;

      # Statusbar
      statusbar.show = "always";

      # Scrollbar
      scrolling.smooth = true;
      scrolling.bar = "when-searching";

      # Downloads
      downloads.position = "bottom";
      downloads.remove_finished = 5000;
      downloads.location.prompt = true;

      # Hints
      hints.chars = "asdfghjkl";

      # Input
      input.insert_mode.auto_load = true;
      input.links_included_in_focus_chain = true;

      # Auto-save session
      auto_save.session = true;

      # Zoom
      zoom.default = "100%";

      # Content settings
      content.autoplay = false;
      content.javascript.clipboard = "access";
    } // lib.optionalAttrs isLinux {
      qt.args = [
        "widevine-path=${widevinePath}"
        "enable-features=WidevineCdm"
      ];
    };

    searchEngines = {
      DEFAULT = "https://www.google.com/search?q={}";
      np = "https://search.nixos.org/packages?type=packages&query={}";
      no = "https://search.nixos.org/options?channel=unstable&from=0&size=50&sort=relevance&type=packages&query={}";
      gh = "https://github.com/search?q={}";
      # Direct GitHub navigation: "gr org/repo" or "gr org"
      gr = "https://github.com/{}";
    };

    keyBindings = {
      normal = {
        # Tabs
        ",t" = "open -t https://www.google.com";
        # GitHub navigation (prompts for org/repo)
        ",g" = "set-cmd-text -s :open -t https://github.com/";
        ",G" = "set-cmd-text -s :open https://github.com/";
        # Userscripts
        ",p" = "spawn --userscript qute-1pass";
        ",m" = "spawn --userscript view_in_mpv";
        ",r" = "spawn --userscript readability";
        # Spoof Chrome UA for current site (fixes broken sites)
        ",u" = "spawn --userscript ${chromeUaSpoof}";
        # Utilities
        ",y" = "yank";
        ",Y" = "yank selection";
        ",b" = "set-cmd-text -s :bookmark-load -t";
        ",B" = "bookmark-add";
        ",h" = "set-cmd-text -s :history";
        ",d" = "download";
      };
    };

    extraConfig = ''
      from qutebrowser.api import interceptor

      # Built-in site_specific_quirks handles: Google, WhatsApp, Slack, Google Docs, Discord
      # Below are additional UA overrides for sites not covered by built-in quirks

      chrome_ua = "Mozilla/5.0 ({os_info}) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0.0.0 Safari/537.36"

      for pattern in [
          "https://*.netflix.com/*",
          "https://*.hulu.com/*",
          "https://*.disneyplus.com/*",
          "https://*.dropout.tv/*",
          "https://*.hbomax.com/*",
          "https://*.max.com/*",
          "https://*.dell.com/*",
          "https://*.ups.com/*",
      ]:
          config.set("content.headers.user_agent", chrome_ua, pattern)

      # Reduce fingerprint surface
      c.content.headers.accept_language = "en-US,en;q=0.5"

      # Old reddit redirect
      def reddit_redirect(info: interceptor.Request):
          url = info.request_url
          if url.host() == "www.reddit.com" or url.host() == "reddit.com":
              url.setHost("old.reddit.com")
              info.redirect(url)

      interceptor.register(reddit_redirect)
    '';
  };

}
