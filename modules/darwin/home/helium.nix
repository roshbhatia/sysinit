{
  pkgs,
  lib,
  config,
  ...
}:
let
  profileRoot = "Library/Application Support/net.imput.helium";
  preferences = pkgs.writeText "helium-preferences.json" (
    builtins.toJSON {
      homepage = "https://www.google.com/";
      homepage_is_newtabpage = false;
      newtab_page_location_override = "https://www.google.com/";
      helium.browser = {
        layout = 1;
        minimal_location_bar = true;
        show_avatar_button = false;
        show_dynamic_new_tab_button = false;
        show_extensions_button = true;
        show_media_button = false;
        show_menu_button = false;
        show_reload_button = false;
        show_vertical_tabs_collapse_button = false;
        zen_mode = false;
      };
      vertical_tabs = {
        collapsed_state = false;
        uncollapsed_width = 200;
      };
      bookmark_bar = {
        show_on_all_tabs = false;
        visibility_state = 2;
      };
      browser = {
        pin_split_tab_button = true;
        theme = {
          color_variant2 = 1;
          user_color2 = -13893377;
        };
      };
      webkit.webprefs = {
        default_fixed_font_size = 13;
        default_font_size = 16;
        fonts = {
          standard.Zyyy = config.sysinit.theme.font.serif;
          serif.Zyyy = config.sysinit.theme.font.serif;
          sansserif.Zyyy = config.sysinit.theme.font.sansSerif;
          fixed.Zyyy = config.sysinit.theme.font.monospace;
          math.Zyyy = "STIX Two Math";
        };
      };
    }
  );
  applyPreferences = pkgs.writeShellScriptBin "helium-settings" ''
    exec ${pkgs.python3}/bin/python3 ${./helium-settings.py} \
      ${preferences} ${lib.escapeShellArg "${config.home.homeDirectory}/${profileRoot}/Default/Preferences"} "$@"
  '';
  extensionIds = [
    "aeblfdkhhhdcdjpifhhbdiojplfjncoa"
    "dbepggeogbaibhgnhhndojpepiihcmeb"
  ];
  extensionFiles = builtins.listToAttrs (
    map (id: {
      name = "${profileRoot}/External Extensions/${id}.json";
      value.text = builtins.toJSON {
        external_update_url = "https://clients2.google.com/service/update2/crx";
      };
    }) extensionIds
  );
in
{
  home = {
    packages = [
      applyPreferences
      pkgs.helium
      (pkgs.writeShellScriptBin "helium-tabs" ''
        exec /usr/bin/osascript -l JavaScript ${./helium-tabs.js} "$@"
      '')
    ];
    activation.heliumPreferences = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      run ${applyPreferences}/bin/helium-settings --defer-running
    '';
    file = extensionFiles // {
      "${profileRoot}/NativeMessagingHosts/com.1password.1password.json".text = builtins.toJSON {
        name = "com.1password.1password";
        description = "1Password BrowserSupport";
        path = "/Applications/1Password.app/Contents/Library/LoginItems/1Password Browser Helper.app/Contents/MacOS/1Password-BrowserSupport";
        type = "stdio";
        allowed_origins = [ "chrome-extension://aeblfdkhhhdcdjpifhhbdiojplfjncoa/" ];
      };
    };
  };
  xdg.configFile."helium/preferences.json".source = preferences;
}
