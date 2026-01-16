{
  lib,
  pkgs,
  values,
  ...
}:

let
  themes = import ../../../../shared/lib/theme { inherit lib; };
  semanticColors = themes.getSemanticColors values.theme.colorscheme values.theme.variant;

  # Strip # from hex colors
  c = color: lib.removePrefix "#" color;

  # Convert hex to 0xRRGGBBAA format for mangowc
  hexToMango = color: "0x${c color}ff";
  hexToMangoAlpha = color: alpha: "0x${c color}${alpha}";

in
{
  # Disable Stylix's theming for mango
  stylix.targets.mango.enable = lib.mkDefault false;

  programs.mango = {
    enable = true;
    systemd.enable = true;

    # Autostart script
    autostart_sh = ''
      # Wallpaper daemon
      ${pkgs.swww}/bin/swww-daemon &
      sleep 1
      ${pkgs.swww}/bin/swww clear ${c semanticColors.background.primary}

      # Status bar
      ${pkgs.waybar}/bin/waybar &

      # Notification daemon
      ${pkgs.mako}/bin/mako &
    '';

    settings = ''
      # ============================================================
      # Visual Effects - matching macOS aesthetic
      # ============================================================

      blur = 1
      blur_layer = 1
      blur_optimized = 1
      blur_params_num_passes = 2
      blur_params_radius = 8
      blur_params_noise = 0.01
      blur_params_brightness = 1.0
      blur_params_contrast = 1.0
      blur_params_saturation = 1.0

      shadows = 1
      layer_shadows = 1
      shadow_only_floating = 0
      shadows_size = 15
      shadows_blur = 20
      shadows_position_x = 0
      shadows_position_y = 5
      shadowscolor = ${hexToMangoAlpha semanticColors.background.primary "80"}

      border_radius = 10
      no_radius_when_single = 0
      focused_opacity = 1.0
      unfocused_opacity = 0.95

      # Border colors
      border_width = 2
      border_focus_color = ${hexToMango semanticColors.accent.primary}
      border_normal_color = ${hexToMango semanticColors.background.secondary}

      # ============================================================
      # Animation - smooth like macOS
      # ============================================================

      animation_type = zoom
      animation_open_duration = 200
      animation_close_duration = 150
      animation_open_initial_scale = 0.9
      animation_close_initial_scale = 1.0
      animation_fade_in = 1
      animation_fade_out = 1

      # ============================================================
      # Layout - tiling with macOS-like gaps
      # ============================================================

      default_layout = tile
      master_factor = 0.55
      nmasters = 1

      gappih = 12
      gappiv = 12
      gappoh = 16
      gappov = 16

      # ============================================================
      # Input
      # ============================================================

      repeat_rate = 50
      repeat_delay = 300

      natural_scroll = 1
      tap_to_click = 1
      disable_while_typing = 1

      # ============================================================
      # Cursor
      # ============================================================

      cursor_size = 24
      follow_mouse = 1

      # ============================================================
      # Key Bindings - macOS-like
      # ============================================================

      # Super+Q = Close window (like Cmd+Q)
      bind = SUPER, q, killclient

      # Super+Space = App launcher (like Spotlight)
      bind = SUPER, space, spawn, ${pkgs.fuzzel}/bin/fuzzel

      # Alt+Enter = Terminal (like aerospace)
      bind = ALT, Return, spawn, ${pkgs.wezterm}/bin/wezterm

      # Alt+E = File manager
      bind = ALT, e, spawn, ${pkgs.nemo}/bin/nemo

      # Super+R = Reload config
      bind = SUPER, r, reload

      # Super+Shift+Q = Quit mango (logout)
      bind = SUPER SHIFT, q, quit

      # ===== Window Focus (vim-style, like aerospace) =====
      bind = ALT, h, focusdir, left
      bind = ALT, j, focusdir, down
      bind = ALT, k, focusdir, up
      bind = ALT, l, focusdir, right

      # ===== Move Windows (alt+cmd on macOS -> alt+shift here) =====
      bind = ALT SHIFT, h, swapdir, left
      bind = ALT SHIFT, j, swapdir, down
      bind = ALT SHIFT, k, swapdir, up
      bind = ALT SHIFT, l, swapdir, right

      # ===== Resize Windows =====
      bind = ALT CTRL, h, resizedir, left, 40
      bind = ALT CTRL, j, resizedir, down, 40
      bind = ALT CTRL, k, resizedir, up, 40
      bind = ALT CTRL, l, resizedir, right, 40

      # ===== Workspaces (tags in mangowc, like aerospace) =====
      # Alt+1, Alt+2 = workspace 1, 2
      bind = ALT, 1, view, 1
      bind = ALT, 2, view, 2

      # Alt+C, Alt+E, Alt+M = Named workspaces (tags 3, 4, 5)
      bind = ALT, c, view, 3
      bind = ALT SHIFT, e, view, 4
      bind = ALT, m, view, 5

      # Alt+Tab / Alt+Shift+Tab = Cycle workspaces
      bind = ALT, Tab, viewnext
      bind = ALT SHIFT, Tab, viewprev

      # ===== Move to Workspace =====
      bind = ALT CTRL, 1, tag, 1
      bind = ALT CTRL, 2, tag, 2
      bind = ALT CTRL, c, tag, 3
      bind = ALT CTRL SHIFT, e, tag, 4
      bind = ALT CTRL, m, tag, 5

      # ===== Layout Controls =====
      # Alt+T = Tile layout
      bind = ALT, t, setlayout, tile

      # Alt+A = Monocle (like accordion/fullscreen-ish)
      bind = ALT, a, setlayout, monocle

      # Alt+S = Scroller layout
      bind = ALT, s, setlayout, scroller

      # Alt+G = Grid layout
      bind = ALT, g, setlayout, grid

      # Alt+F = Fullscreen
      bind = ALT, f, fullscreen

      # Alt+V = Toggle floating
      bind = ALT, v, togglefloating

      # Super+Tab = Focus next window
      bind = SUPER, Tab, focusnext

      # ===== Mouse Bindings =====
      bindm = SUPER, mouse:272, movewindow
      bindm = SUPER, mouse:273, resizewindow

      # ============================================================
      # Window Rules
      # ============================================================

      # Float certain windows
      windowrule = float, title:^(Picture-in-Picture)$
      windowrule = float, class:^(pavucontrol)$
      windowrule = float, class:^(1Password)$
      windowrule = float, class:^(nemo)$

      # Assign apps to workspaces (like aerospace)
      # Tag 3 = Chat apps
      windowrule = tag 3, class:^(discord)$
      windowrule = tag 3, class:^(slack)$
      windowrule = tag 3, class:^(ferdium)$

      # Tag 4 = Email
      windowrule = tag 4, class:^(thunderbird)$

      # Tag 5 = Media
      windowrule = tag 5, class:^(spotify)$
    '';
  };
}
