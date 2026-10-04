{
  config,
  lib,
  pkgs,
  ...
}:

let
  format = pkgs.formats.toml { };
  python = pkgs.python3.withPackages (p: [ p.tomlkit ]);
  settings = format.generate "slk-settings.toml" config.sysinit.slk.settings;
  colors = (import ../../shared/theme-colors.nix { inherit lib; }).colorsOf config;
in

{
  options.sysinit.slk.settings = lib.mkOption {
    inherit (format) type;
    default = { };
    description = "Managed slk preferences, merged into its writable config.";
  };

  config = {
    sysinit.slk.settings = {
      general = {
        use_slack_sections = lib.mkDefault true;
        download_dir = lib.mkDefault "${config.home.homeDirectory}/Downloads";
      };
      appearance = {
        theme = lib.mkDefault "ANSI Dark";
        timestamp_format = lib.mkDefault "3:04 PM";
        image_protocol = lib.mkDefault "auto";
        max_image_rows = lib.mkDefault 20;
        max_image_cols = lib.mkDefault 60;
        mouse_wheel_lines = lib.mkDefault 3;
        emoji_images = lib.mkDefault "on";
        emoji_cells = lib.mkDefault 2;
        colored_usernames = lib.mkDefault true;
      };
      animations.typing_indicators = lib.mkDefault true;
      notifications = {
        enabled = lib.mkDefault true;
        on_mention = lib.mkDefault true;
        on_dm = lib.mkDefault true;
      };
      cache.max_image_cache_mb = lib.mkDefault 200;
      sidebar = {
        width = lib.mkDefault 26;
        hide_inactive_after_days = lib.mkDefault 30;
      };
      compose.editor = lib.mkDefault "nvim";
    };

    home.activation.slkPreferences = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      run ${python}/bin/python3 ${./slk-setup.py} \
        ${lib.escapeShellArg "${config.xdg.configHome}/slk/config.toml"} ${settings}
    '';

    home.packages = [ pkgs.slk ];

    xdg.configFile."slk/themes/sysinit-ansi-dark.toml".text = ''
      name = "ANSI Dark"

      [colors]
      primary = "#${colors.base0D}"
      accent = "#${colors.base0B}"
      warning = "#${colors.base0A}"
      error = "#${colors.base08}"
      background = "#${colors.base00}"
      surface = "#${colors.base01}"
      surface_dark = "#${colors.base00}"
      text = "#${colors.base05}"
      text_muted = "#${colors.base03}"
      border = "#${colors.base02}"
      sidebar_background = "#${colors.base01}"
      sidebar_text = "#${colors.base05}"
      sidebar_text_muted = "#${colors.base04}"
      rail_background = "#${colors.base00}"
      selection_background = "#${colors.base0D}"
      selection_foreground = "#${colors.base00}"
      search_highlight_bg = "#${colors.base0A}"
      search_highlight_fg = "#${colors.base00}"
    '';
  };
}
