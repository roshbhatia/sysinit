{
  lib,
  values,
  pkgs,
  ...
}:

let
  themes = import ../../../shared/lib/theme { inherit lib; };
  hyprlandAdapter = import ./lib.nix { inherit lib; };
  theme = themes.getTheme values.theme.colorscheme;
  hyprlandTheme = hyprlandAdapter.createHyprlandTheme theme values.theme;
  colors = hyprlandTheme.hyprlandColors;
in
{
  wayland.windowManager.hyprland = {
    enable = true;
    package = pkgs.hyprland;
    systemd.enable = true;

    settings = {
      # Monitor configuration
      monitor = ",preferred,auto,auto";

      # General settings
      general = {
        gaps_in = 4;
        gaps_out = 8;
        border_size = 3;
        "col.active_border" = lib.mkForce "rgb(${lib.strings.removePrefix "#" colors.activeBorder})";
        "col.inactive_border" = lib.mkForce "rgb(${lib.strings.removePrefix "#" colors.inactiveBorder})";
        layout = "master";
        allow_tearing = false;
      };

      decoration = {
        rounding = 8;
        active_opacity = 0.95;
        inactive_opacity = 0.85;
        blur = {
          enabled = true;
          size = 3;
          passes = 1;
          ignore_opacity = false;
        };
        shadow = {
          enabled = true;
          range = 4;
          render_power = 3;
          color = lib.mkForce "rgba(0000001a)";
        };
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
          tap-to-click = true;
        };

        sensitivity = 0.0;
      };

      # Master layout configuration
      master = {
        new_status = "master";
        new_on_top = false;
        always_center_master = false;
        mfact = 0.55;
      };

      # Misc settings
      misc = {
        force_default_wallpaper = 0;
        disable_hyprland_logo = true;
        animate_manual_resizes = false;
        enable_swallow = true;
        swallow_regex = "^(wezterm)$";
      };

      # Startup commands
      exec-once = [ "waybar" ];

      # Keybindings - Aerospace-style
      bind = [
        # Focus movement (Super+hjkl)
        "SUPER, h, movefocus, l"
        "SUPER, j, movefocus, d"
        "SUPER, k, movefocus, u"
        "SUPER, l, movefocus, r"

        # Move windows (Super+Shift+hjkl)
        "SUPER SHIFT, h, movewindow, l"
        "SUPER SHIFT, j, movewindow, d"
        "SUPER SHIFT, k, movewindow, u"
        "SUPER SHIFT, l, movewindow, r"

        # Workspaces (Super+1-9)
        "SUPER, 1, workspace, 1"
        "SUPER, 2, workspace, 2"
        "SUPER, 3, workspace, 3"
        "SUPER, 4, workspace, 4"
        "SUPER, 5, workspace, 5"
        "SUPER, 6, workspace, 6"
        "SUPER, 7, workspace, 7"
        "SUPER, 8, workspace, 8"
        "SUPER, 9, workspace, 9"

        # Move to workspace (Super+Shift+1-9)
        "SUPER SHIFT, 1, movetoworkspace, 1"
        "SUPER SHIFT, 2, movetoworkspace, 2"
        "SUPER SHIFT, 3, movetoworkspace, 3"
        "SUPER SHIFT, 4, movetoworkspace, 4"
        "SUPER SHIFT, 5, movetoworkspace, 5"
        "SUPER SHIFT, 6, movetoworkspace, 6"
        "SUPER SHIFT, 7, movetoworkspace, 7"
        "SUPER SHIFT, 8, movetoworkspace, 8"
        "SUPER SHIFT, 9, movetoworkspace, 9"

        # Cycle workspaces (Super+Tab)
        "SUPER, tab, workspace, e+1"
        "SUPER SHIFT, tab, workspace, e-1"

        # Window management
        "SUPER, f, fullscreen, 0"
        "SUPER SHIFT, f, fullscreen, 1"
        "SUPER, q, killactive"

        # App launcher (Super+Space)
        "SUPER, space, exec, wofi --show=drun"

        # Terminal
        "SUPER, t, exec, wezterm"

        # Screenshot
        "SUPER, s, exec, hyprshot -m region"
        "SUPER SHIFT, s, exec, hyprshot -m window"
        "SUPER CTRL, s, exec, hyprshot -m output"

        # Quit (Super+Escape)
        "SUPER, escape, exit"
      ];

      # Mouse bindings
      bindm = [
        "SUPER, mouse:272, movewindow"
        "SUPER, mouse:273, resizewindow"
      ];

      # Window rules
      windowrule = [
        # Floating windows
        "float, ^(pavucontrol)$"
        "float, ^(nm-connection-editor)$"
        "float, ^(blueman-manager)$"
        "float, ^(file-roller)$"
        "float, ^(1Password)$"

        # Workspace assignments
        "workspace 3, ^(org\.ferdium\.)$"
        "workspace 3, ^(Slack)$"
        "workspace 3, ^(discord)$"
        "workspace 4, ^(thunderbird)$"
        "workspace 4, ^(evolution)$"
        "workspace 5, ^(spotify)$"
        "workspace 5, ^(Audacious)$"
      ];

      # Window rule v2 (more advanced options)
      windowrulev2 = [
        "suppressevent maximize, class:.*"
      ];
    };

    extraConfig = ''
      # Additional custom keybindings if needed
    '';
  };
}
