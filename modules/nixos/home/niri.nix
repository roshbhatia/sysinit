{
  lib,
  theme,
  ...
}:

let
  themes = import ../../../../shared/lib/theme { inherit lib; };

  validatedTheme = themes.validateThemeConfig theme;
  themeObj = themes.getTheme validatedTheme.colorscheme;

  niriAdapter = themes.adapters.niri;
  niriThemeConfig = niriAdapter.createNiriTheme themeObj validatedTheme;
in
{
  wayland.windowManager.niri = {
    enable = true;

    settings = {
      input = {
        keyboard = {
          xkb = {
            layout = "us";
          };
        };
        touchpad = {
          natural-scroll = false;
          tap = true;
        };
      };

      output = {
        default-scale = 1.0;
      };

      layout = {
        gaps = 12;
        border = {
          width = 2;
          active-color = niriThemeConfig.niriColors.activeBorder;
          inactive-color = niriThemeConfig.niriColors.inactiveBorder;
        };
        focus-ring = {
          width = 2;
          active-color = niriThemeConfig.niriColors.activeBorder;
          inactive-color = niriThemeConfig.niriColors.inactiveBorder;
        };
      };

      spawn-at-startup = [
        { command = [ "waybar" ]; }
      ];

      binds = with lib; {
        "Mod+Return" = { action = "Spawn"; command = [ "foot" ]; };
        "Mod+Space" = { action = "Spawn"; command = [ "wofi" "--show=drun" ]; };
        "Mod+H" = { action = "FocusColumnLeft"; };
        "Mod+J" = { action = "FocusWindowDown"; };
        "Mod+K" = { action = "FocusWindowUp"; };
        "Mod+L" = { action = "FocusColumnRight"; };
        "Mod+Shift+H" = { action = "MoveColumnLeft"; };
        "Mod+Shift+J" = { action = "MoveWindowDown"; };
        "Mod+Shift+K" = { action = "MoveWindowUp"; };
        "Mod+Shift+L" = { action = "MoveColumnRight"; };
        "Mod+Plus" = { action = "IncreaseColumnWidth"; data = 50; };
        "Mod+Minus" = { action = "DecreaseColumnWidth"; data = 50; };
        "Mod+1" = { action = "GoToWorkspace"; workspace = 1; };
        "Mod+2" = { action = "GoToWorkspace"; workspace = 2; };
        "Mod+3" = { action = "GoToWorkspace"; workspace = 3; };
        "Mod+Shift+1" = { action = "MoveWindowToWorkspace"; workspace = 1; };
        "Mod+Shift+2" = { action = "MoveWindowToWorkspace"; workspace = 2; };
        "Mod+Shift+3" = { action = "MoveWindowToWorkspace"; workspace = 3; };
        "Mod+Tab" = { action = "GoToWorkspace"; relative = 1; };
        "Mod+Shift+Tab" = { action = "GoToWorkspace"; relative = -1; };
        "Mod+F" = { action = "Fullscreen"; };
        "Mod+Slash" = { action = "SwitchLayout"; };
      };
    };
  };
}
