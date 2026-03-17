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

      # DRM support (Widevine) — NixOS only
      content.widevine = isLinux;

      # Tab behavior
      tabs.position = "top";
      tabs.show = "multiple";
      tabs.last_close = "default-page";

      # Completion
      completion.shrink = true;

      # Downloads
      downloads.position = "bottom";
      downloads.remove_finished = 5000;

      # Scrolling
      scrolling.smooth = true;

      # URL handling
      url.default_page = "about:blank";
      url.start_pages = [ "about:blank" ];
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
    };

    keyBindings = {
      normal = {
        # 1Password fill
        ",p" = "spawn --userscript qute-1pass";
        # View in mpv (built-in userscript, also handles SponsorBlock if mpv has the plugin)
        ",m" = "spawn --userscript view_in_mpv";
      };
    };

    # Old reddit redirect via URL rewriting
    extraConfig = ''
      import re
      from qutebrowser.api import interceptor

      def reddit_redirect(info: interceptor.Request):
          url = info.request_url
          if url.host() == "www.reddit.com" or url.host() == "reddit.com":
              url.setHost("old.reddit.com")
              info.redirect(url)

      interceptor.register(reddit_redirect)
    '';
  };

}
