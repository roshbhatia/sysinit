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
      "$mainMod" = "ALT";

      # Monitor config - auto-detect with good defaults
      monitor = [
        ",preferred,auto,auto"
      ];

      input = {
        kb_layout = "us";
        repeat_rate = 50;
        repeat_delay = 300;
        follow_mouse = 1;
        sensitivity = 0;
        touchpad = {
          natural_scroll = true;
          disable_while_typing = true;
          tap-to-click = false;
        };
      };

      gestures = {
        workspace_swipe = true;
        workspace_swipe_fingers = 3;
        workspace_swipe_distance = 300;
        workspace_swipe_cancel_ratio = 0.5;
      };

      general = {
        gaps_in = 5;
        gaps_out = 10;
        border_size = 2;
        "col.active_border" = hexToHyprland semanticColors.accent.primary;
        "col.inactive_border" = hexToHyprland semanticColors.background.secondary;
        resize_on_border = true;
        layout = "dwindle";
        allow_tearing = false;
      };

      decoration = {
        rounding = 10;

        active_opacity = 1.0;
        inactive_opacity = 0.95;

        blur = {
          enabled = true;
          size = 5;
          passes = 3;
          new_optimizations = true;
          ignore_opacity = true;
        };

        shadow = {
          enabled = true;
          range = 20;
          render_power = 3;
          color = hexToHyprlandAlpha semanticColors.background.primary "99";
        };
      };

      animations = {
        enabled = true;
        bezier = [
          "ease,0.25,0.1,0.25,1"
          "easeOut,0,0,0.2,1"
          "easeInOut,0.42,0,0.58,1"
        ];
        animation = [
          "windows,1,4,ease,slide"
          "windowsOut,1,4,easeOut,slide"
          "fade,1,4,ease"
          "workspaces,1,4,easeInOut,slide"
          "border,1,4,ease"
        ];
      };

      dwindle = {
        pseudotile = true;
        preserve_split = true;
        force_split = 2;
        smart_split = false;
        smart_resizing = true;
      };

      master = {
        new_status = "master";
      };

      misc = {
        force_default_wallpaper = 0;
        disable_hyprland_logo = true;
        disable_splash_rendering = true;
        mouse_move_enables_dpms = true;
        key_press_enables_dpms = true;
        background_color = hexToHyprland semanticColors.background.primary;
      };

      # Window rules for cleaner look
      windowrulev2 = [
        "opacity 0.95 0.85,class:^(wezterm)$"
        "float,class:^(pavucontrol)$"
        "float,title:^(Picture-in-Picture)$"
        "pin,title:^(Picture-in-Picture)$"
      ];

      bind = [
        # Focus with ALT + H/J/K/L (vim-style)
        "$mainMod, H, movefocus, l"
        "$mainMod, J, movefocus, d"
        "$mainMod, K, movefocus, u"
        "$mainMod, L, movefocus, r"

        # Move windows with ALT + SHIFT + H/J/K/L
        "$mainMod SHIFT, H, movewindow, l"
        "$mainMod SHIFT, J, movewindow, d"
        "$mainMod SHIFT, K, movewindow, u"
        "$mainMod SHIFT, L, movewindow, r"

        # Resize windows with ALT + CTRL + H/J/K/L
        "$mainMod CTRL, H, resizeactive, -50 0"
        "$mainMod CTRL, J, resizeactive, 0 50"
        "$mainMod CTRL, K, resizeactive, 0 -50"
        "$mainMod CTRL, L, resizeactive, 50 0"

        # Workspaces 1-4
        "$mainMod, 1, workspace, 1"
        "$mainMod, 2, workspace, 2"
        "$mainMod, 3, workspace, 3"
        "$mainMod, 4, workspace, 4"

        # Move window to workspace
        "$mainMod SHIFT, 1, movetoworkspace, 1"
        "$mainMod SHIFT, 2, movetoworkspace, 2"
        "$mainMod SHIFT, 3, movetoworkspace, 3"
        "$mainMod SHIFT, 4, movetoworkspace, 4"

        # Workspace cycling
        "$mainMod, TAB, workspace, e+1"
        "$mainMod SHIFT, TAB, workspace, e-1"

        # Window management
        "$mainMod, F, fullscreen, 0"
        "$mainMod, M, fullscreen, 1"
        "$mainMod, V, togglefloating,"
        "$mainMod, P, pseudo,"
        "$mainMod, S, togglesplit,"

        # Applications
        "$mainMod, RETURN, exec, ${pkgs.wezterm}/bin/wezterm"
        "$mainMod, D, exec, ${pkgs.fuzzel}/bin/fuzzel"
        "$mainMod, E, exec, ${pkgs.nemo}/bin/nemo"

        # Kill and reload
        "$mainMod SHIFT, Q, killactive,"
        "$mainMod, ESC, exec, ${pkgs.hyprland}/bin/hyprctl reload"

        # Screenshot
        ", Print, exec, ${pkgs.grim}/bin/grim -g \"$(${pkgs.slurp}/bin/slurp)\" - | ${pkgs.wl-clipboard}/bin/wl-copy"
        "SHIFT, Print, exec, ${pkgs.grim}/bin/grim - | ${pkgs.wl-clipboard}/bin/wl-copy"
      ];

      # Mouse bindings
      bindm = [
        "$mainMod, mouse:272, movewindow"
        "$mainMod, mouse:273, resizewindow"
      ];

      exec-once = [
        # Set solid color wallpaper from theme
        "${pkgs.swaybg}/bin/swaybg -c '${semanticColors.background.primary}'"
        # Note: waybar and mako are started via systemd user services
      ];
    };
  };
}
