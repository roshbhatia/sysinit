{
  lib,
  pkgs,
  values,
  ...
}:

let
  themes = import ../../../../shared/lib/theme { inherit lib; };
  semanticColors = themes.getSemanticColors values.theme.colorscheme values.theme.variant;

  # Convert #rrggbb to rgb(rrggbb) format for Hyprland
  hexToHyprland = color: "rgb(${lib.removePrefix "#" color})";
  hexToHyprlandAlpha = color: alpha: "rgba(${lib.removePrefix "#" color}${alpha})";

in
{
  # Disable Stylix's Hyprland theming - using custom theme colors
  stylix.targets.hyprland.enable = false;

  wayland.windowManager.hyprland = {
    enable = true;
    xwayland.enable = true;
    settings = {
      # Use SUPER (Windows/Command key) like macOS
      "$mod" = "SUPER";

      # Monitor - auto-detect
      monitor = [ ",preferred,auto,auto" ];

      input = {
        kb_layout = "us";
        repeat_rate = 50;
        repeat_delay = 300;
        follow_mouse = 1;
        touchpad = {
          natural_scroll = true;
          disable_while_typing = true;
        };
      };

      gestures = {
        workspace_swipe = true;
        workspace_swipe_fingers = 3;
      };

      general = {
        gaps_in = 4;
        gaps_out = 8;
        border_size = 2;
        "col.active_border" = hexToHyprland semanticColors.accent.primary;
        "col.inactive_border" = hexToHyprland semanticColors.background.secondary;
        layout = "dwindle";
      };

      decoration = {
        rounding = 10;
        active_opacity = 1.0;
        inactive_opacity = 0.95;

        blur = {
          enabled = true;
          size = 5;
          passes = 2;
        };

        shadow = {
          enabled = true;
          range = 15;
          color = hexToHyprlandAlpha semanticColors.background.primary "80";
        };
      };

      animations = {
        enabled = true;
        bezier = [ "ease,0.25,0.1,0.25,1" ];
        animation = [
          "windows,1,3,ease,slide"
          "fade,1,3,ease"
          "workspaces,1,3,ease,slide"
        ];
      };

      dwindle = {
        preserve_split = true;
        force_split = 2;
      };

      misc = {
        force_default_wallpaper = 0;
        disable_hyprland_logo = true;
        disable_splash_rendering = true;
        background_color = hexToHyprland semanticColors.background.primary;
      };

      # Window rules
      windowrulev2 = [
        "opacity 0.95 0.90,class:^(wezterm)$"
        "float,class:^(pavucontrol)$"
        "float,title:^(Picture-in-Picture)$"
      ];

      bind = [
        # ===== Applications (macOS-like) =====
        "$mod, RETURN, exec, ${pkgs.wezterm}/bin/wezterm"
        "$mod, SPACE, exec, ${pkgs.fuzzel}/bin/fuzzel"
        "$mod, E, exec, ${pkgs.nemo}/bin/nemo"

        # ===== Window Focus (vim-style) =====
        "$mod, H, movefocus, l"
        "$mod, J, movefocus, d"
        "$mod, K, movefocus, u"
        "$mod, L, movefocus, r"

        # ===== Move Windows =====
        "$mod SHIFT, H, movewindow, l"
        "$mod SHIFT, J, movewindow, d"
        "$mod SHIFT, K, movewindow, u"
        "$mod SHIFT, L, movewindow, r"

        # ===== Resize Windows =====
        "$mod CTRL, H, resizeactive, -40 0"
        "$mod CTRL, J, resizeactive, 0 40"
        "$mod CTRL, K, resizeactive, 0 -40"
        "$mod CTRL, L, resizeactive, 40 0"

        # ===== Workspaces =====
        "$mod, 1, workspace, 1"
        "$mod, 2, workspace, 2"
        "$mod, 3, workspace, 3"
        "$mod, 4, workspace, 4"
        "$mod, TAB, workspace, e+1"
        "$mod SHIFT, TAB, workspace, e-1"

        # ===== Move to Workspace =====
        "$mod SHIFT, 1, movetoworkspace, 1"
        "$mod SHIFT, 2, movetoworkspace, 2"
        "$mod SHIFT, 3, movetoworkspace, 3"
        "$mod SHIFT, 4, movetoworkspace, 4"

        # ===== Window Management =====
        "$mod, F, fullscreen, 0"
        "$mod, V, togglefloating,"
        "$mod SHIFT, Q, killactive,"

        # ===== System =====
        "$mod, ESC, exec, ${pkgs.hyprland}/bin/hyprctl reload"
      ];

      # Mouse bindings
      bindm = [
        "$mod, mouse:272, movewindow"
        "$mod, mouse:273, resizewindow"
      ];

      # Startup
      exec-once = [
        # Wallpaper - use swww for dynamic wallpapers
        "${pkgs.swww}/bin/swww-daemon"
        "${pkgs.swww}/bin/swww img ${pkgs.writeText "blank" ""} --transition-type none || ${pkgs.swww}/bin/swww clear ${lib.removePrefix "#" semanticColors.background.primary}"
      ];
    };
  };
}
