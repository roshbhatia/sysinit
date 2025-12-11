{
  values,
  utils,
  ...
}:

let
  themes = utils.theme;
  theme = values.theme;

  themeObj = themes.getTheme theme.colorscheme;

  niriAdapter = themes.adapters.niri;
  niriThemeConfig = niriAdapter.createNiriTheme themeObj validatedTheme;
in
{
  programs.niri.settings = {
    input = {
      keyboard.xkb.layout = "us";

      touchpad = {
        natural-scroll = false;
        tap = true;
      };
    };

    layout = {
      gaps = 12;

      border = {
        width = 2;
        active.color = niriThemeConfig.niriColors.activeBorder;
        inactive.color = niriThemeConfig.niriColors.inactiveBorder;
      };

      focus-ring = {
        width = 2;
        active.color = niriThemeConfig.niriColors.activeBorder;
        inactive.color = niriThemeConfig.niriColors.inactiveBorder;
      };
    };

    spawn-at-startup = [
      { command = [ "waybar" ]; }
    ];

    binds = {
      "Mod+Return".action.spawn = [ "foot" ];
      "Mod+Space".action.spawn = [
        "wofi"
        "--show=drun"
      ];

      "Mod+H".action.focus-column-left = { };
      "Mod+J".action.focus-window-down = { };
      "Mod+K".action.focus-window-up = { };
      "Mod+L".action.focus-column-right = { };

      "Mod+Shift+H".action.move-column-left = { };
      "Mod+Shift+J".action.move-window-down = { };
      "Mod+Shift+K".action.move-window-up = { };
      "Mod+Shift+L".action.move-column-right = { };

      "Mod+Equal".action.set-column-width = "+10%";
      "Mod+Minus".action.set-column-width = "-10%";

      "Mod+1".action.focus-workspace = 1;
      "Mod+2".action.focus-workspace = 2;
      "Mod+3".action.focus-workspace = 3;

      "Mod+Shift+1".action.move-column-to-workspace = 1;
      "Mod+Shift+2".action.move-column-to-workspace = 2;
      "Mod+Shift+3".action.move-column-to-workspace = 3;

      "Mod+Tab".action.focus-workspace-down = { };
      "Mod+Shift+Tab".action.focus-workspace-up = { };

      "Mod+F".action.maximize-column = { };
      "Mod+Shift+F".action.fullscreen-window = { };
      "Mod+Slash".action.switch-preset-column-width = { };

      "Mod+Q".action.close-window = { };
    };
  };
}
