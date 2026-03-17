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

      # Start/new tab pages
      url.default_page = "https://www.google.com";
      url.start_pages = [ "https://www.google.com" ];

      # Tab behavior (Firefox-like)
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

      # Window title (Firefox-like)
      window.title_format = "{perc}{current_title}{title_sep}qutebrowser";

      # Completion
      completion.shrink = true;
      completion.use_best_match = false;

      # Statusbar
      statusbar.show = "always";

      # Scrollbar
      scrolling.smooth = true;
      scrolling.bar = "when-searching";

      # Downloads (Firefox-like)
      downloads.position = "bottom";
      downloads.remove_finished = 5000;
      downloads.location.prompt = true;

      # Hints
      hints.chars = "asdfghjkl";

      # Input
      input.insert_mode.auto_load = true;
      input.links_included_in_focus_chain = true;

      # Auto-save session (like Firefox restore)
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
    };

    keyBindings = {
      normal = {
        # Firefox-like keybindings
        "<Ctrl-t>" = "open -t";
        "<Ctrl-w>" = "tab-close";
        "<Ctrl-Shift-t>" = "undo";
        "<Ctrl-Tab>" = "tab-next";
        "<Ctrl-Shift-Tab>" = "tab-prev";
        "<Ctrl-l>" = "set-cmd-text :open {url:pretty}";
        "<Ctrl-r>" = "reload";
        "<Ctrl-Shift-r>" = "reload -f";
        "<Ctrl-f>" = "set-cmd-text /";
        "<Ctrl-d>" = "bookmark-add";
        "<Ctrl-Shift-b>" = "config-cycle statusbar.show always never";
        "<Ctrl-j>" = "download-open";
        "<Alt-Left>" = "back";
        "<Alt-Right>" = "forward";
        "<Ctrl-plus>" = "zoom-in";
        "<Ctrl-minus>" = "zoom-out";
        "<Ctrl-0>" = "zoom";

        # 1Password fill
        ",p" = "spawn --userscript qute-1pass";
        # View in mpv
        ",m" = "spawn --userscript view_in_mpv";
      };
      insert = {
        # Allow Ctrl-a/c/v/x in input fields (Firefox-like)
        "<Ctrl-a>" = "fake-key <Ctrl-a>";
        "<Ctrl-v>" = "fake-key <Ctrl-v>";
        "<Ctrl-c>" = "fake-key <Ctrl-c>";
        "<Ctrl-x>" = "fake-key <Ctrl-x>";
        "<Ctrl-z>" = "fake-key <Ctrl-z>";
        # Escape insert mode
        "<Escape>" = "mode-leave";
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
