{
  pkgs,
  values,
  ...
}:

let
  themes = import ../../../shared/lib/theme { inherit lib; };
  semanticColors = themes.getSemanticColors values.theme.colorscheme values.theme.variant;

in
{
  wayland.windowManager.hyprland = {
    enable = true;
    xwayland.enable = true;
    settings = {
      "$mainMod" = "ALT";

      input = {
        kb_layout = "us";
        repeat_rate = 50;
        numlock_by_default = "disabled";
        follow_mouse = 1;
        touchpad = {
          natural_scroll = "true";
          disable_while_typing = "true";
          tap-to-click = "false";
          drag-lock = "disabled";
        };
      };

      gestures = {
        workspace_swipe = "on";
        workspace_swipe_fingers = "3";
        workspace_swipe_distance = "200";
        workspace_swipe_invert = "false";
      };

      general = {
        gaps_in = 4;
        gaps_out = 8;
        border_size = 1;
        "col.active_border" = semanticColors.accent.primary;
        "col.inactive_border" = semanticColors.background.secondary;
        resize_on_border = "false";
        layout = "dwindle";
      };

      decoration = {
        rounding = 8;
        blur = {
          enabled = true;
          size = 3;
          passes = 2;
        };
        drop_shadow = true;
      };

      bind = [
        # Focus with ALT + H/J/K/L
        "$mainMod, H, movefocus, l"
        "$mainMod, J, movefocus, d"
        "$mainMod, K, movefocus, u"
        "$mainMod, L, movefocus, r"

        # Move with ALT + SHIFT + H/J/K/L
        "$mainMod SHIFT, H, movewindow, l"
        "$mainMod SHIFT, J, movewindow, d"
        "$mainMod SHIFT, K, movewindow, u"
        "$mainMod SHIFT, L, movewindow, r"

        # Workspaces
        "$mainMod, 1, workspace, 1"
        "$mainMod, 2, workspace, 2"
        "$mainMod, 3, workspace, 3"
        "$mainMod, 4, workspace, 4"

        # Move to workspace

        # Fullscreen
        "$mainMod, F, fullscreen, 0"

        # Workspace switch (wrap)
        "$mainMod, TAB, workspace, e+1"
        "$mainMod SHIFT TAB, workspace, e-1"

        # Reload config
        "$mainMod, ESC, exec, ${pkgs.hyprland}/bin/hyprctl reload"

        # Launch terminal (wezterm)
        "$mainMod, RETURN, exec, ${pkgs.wezterm}"

        # Kill active window
        "$mainMod SHIFT, Q, killactive,"
      ];
    };
  };
}
