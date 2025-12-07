{
  values,
  utils,
  ...
}:

let
  themes = utils.theme;
  theme = values.theme;

  validatedTheme = themes.validateThemeConfig theme;
  themeObj = themes.getTheme validatedTheme.colorscheme;

  hyprlandAdapter = themes.adapters.hyprland;
  hyprlandThemeConfig = hyprlandAdapter.createHyprlandTheme themeObj validatedTheme;
in
{
  wayland.windowManager.hyprland = {
    enable = true;

    settings = {
      monitor = ",preferred,auto,1";

      general = {
        gaps_in = 12;
        gaps_out = 16;
        border_size = 2;
        "col.active_border" =
          "rgba(${hyprlandThemeConfig.hyprlandColors.activeBorder}ee) rgba(${hyprlandThemeConfig.hyprlandColors.activeBorder}99) 45deg";
        "col.inactive_border" = "rgba(${hyprlandThemeConfig.hyprlandColors.inactiveBorder}aa)";
        resize_on_border = true;
        allow_tearing = false;
        layout = "dwindle";
      };

      decoration = {
        rounding = 10;
        blur.enabled = true;
        blur.size = 3;
        blur.passes = 1;
        drop_shadow = true;
        shadow_range = 4;
        shadow_render_power = 3;
        "col.shadow" = "rgba(${hyprlandThemeConfig.hyprlandColors.shadowColor}ee)";
      };

      animations = {
        enabled = true;
        bezier = "myBezier, 0.05, 0.9, 0.1, 1.05";
        animation = [
          "windows, 1, 10, myBezier"
          "windowsOut, 1, 10, default, popin 80%"
          "border, 1, 10, default"
          "borderangle, 1, 8, default"
          "fade, 1, 7, default"
          "workspaces, 1, 6, default"
        ];
      };

      input = {
        kb_layout = "us";
        kb_variant = "";
        kb_model = "";
        kb_options = "";
        kb_rules = "";
        follow_mouse = 1;
        mouse_refocus = true;
        touchpad = {
          natural_scroll = false;
          disable_while_typing = true;
        };
      };

      gestures = {
        workspace_swipe = false;
      };

      misc = {
        force_default_wallpaper = -1;
        disable_hyprland_logo = false;
        allow_session_lock_restore = true;
      };

      "$mod" = "ALT";
      "$modCtrl" = "ALT CTRL";
      "$modShift" = "ALT SHIFT";

      bind = [
        "$mod, slash, togglesplit,"
        "$mod, f, fullscreen, 0"
        "$mod, h, movefocus, l"
        "$mod, j, movefocus, d"
        "$mod, k, movefocus, u"
        "$mod, l, movefocus, r"
        "$mod, 1, workspace, 1"
        "$mod, 2, workspace, 2"
        "$mod, 3, workspace, 3"
        "$mod, c, workspace, name:C"
        "$mod, m, workspace, name:M"
        "$mod, s, workspace, name:S"
        "$mod, e, workspace, name:E"
        "$mod, Tab, workspace, next"
        "$modShift, Tab, workspace, prev"
        "$mod, space, togglespecialworkspace,"
        "$mod, Return, exec, hyprctl reload"
      ];

      binde = [
        "$mod, minus, resizeactive, -70 0"
        "$mod, equal, resizeactive, 70 0"
        "$modShift, minus, resizeactive, -210 0"
        "$modShift, equal, resizeactive, 210 0"
      ];

      bindm = [
        "$mod, mouse:272, movewindow"
        "$mod, mouse:273, resizewindow"
      ];

      windowrule = [
        "float, class:^(org.gnome.Settings)$"
        "float, title:^(1Password)$"
        "float, class:^(file-roller)$"
        "float, class:^(Lxappearance)$"
        "float, class:^(pavucontrol)$"
        "float, class:^(nwg-look)$"
        "float, class:^(qt5ct)$"
        "float, class:^(qt6ct)$"
      ];

      workspacerules = [
        "name:C, gapsIn:12, gapsOut:16"
        "name:M, gapsIn:12, gapsOut:16"
        "name:E, gapsIn:12, gapsOut:16"
      ];

      exec-once = [
        "waybar &"
      ];
    };
  };
}
