# Home desktop configuration: mangowc, waybar, fuzzel, mako, nemo
{
  config,
  lib,
  pkgs,
  ...
}:

let
  c = color: lib.removePrefix "#" color;
  hexToMango = color: "0x${c color}ff";
  hexToMangoAlpha = color: alpha: "0x${c color}${alpha}";
  inherit (config.sysinit.theme.transparency) opacity;

  colors = config.lib.stylix.colors;

  semanticColors = {
    background = {
      primary = "#${colors.base00}";
      secondary = "#${colors.base01}";
      tertiary = "#${colors.base02}";
      overlay = "#${colors.base01}";
    };
    foreground = {
      primary = "#${colors.base05}";
      secondary = "#${colors.base04}";
      muted = "#${colors.base03}";
      subtle = "#${colors.base03}";
    };
    accent = {
      primary = "#${colors.base0D}";
      secondary = "#${colors.base0C}";
      tertiary = "#${colors.base0E}";
      dim = "#${colors.base02}";
    };
    semantic = {
      error = "#${colors.base08}";
      warning = "#${colors.base0A}";
      success = "#${colors.base0B}";
      info = "#${colors.base0D}";
    };
    syntax = {
      keyword = "#${colors.base0E}";
      string = "#${colors.base0B}";
      number = "#${colors.base09}";
      comment = "#${colors.base03}";
      function = "#${colors.base0D}";
      variable = "#${colors.base08}";
      type = "#${colors.base0A}";
      operator = "#${colors.base05}";
      constant = "#${colors.base09}";
      builtin = "#${colors.base0C}";
    };
  };

  wallpaper = pkgs.fetchurl {
    url = "https://preview.redd.it/58ugyimgkj661.jpg?auto=webp&s=5db2c277e7e8e8fe7389ff64ea1b9c252fca7e01";
    sha256 = "1v2yn0aan04rqp70ybv1485isgk9jq0gv5r6lqv1hin6y279pf83";
  };
in
{
  stylix.targets = {
    waybar.enable = false;
    fuzzel.enable = false;
    mako.enable = false;
  };

  wayland.windowManager.mango = {
    enable = true;
    systemd.enable = true;

    autostart_sh = ''
      ${pkgs.swww}/bin/swww-daemon &
      sleep 1
      ${pkgs.swww}/bin/swww img $HOME/.background-image --transition-type fade --transition-duration 1
      ${pkgs.waybar}/bin/waybar &
      ${pkgs.mako}/bin/mako &
    '';

    settings = ''
      # Visual Effects
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
      shadowscolor = ${hexToMangoAlpha "#${config.lib.stylix.colors.base00}" "80"}

      border_radius = 10
      no_radius_when_single = 0
      focused_opacity = 1.0
      unfocused_opacity = ${toString opacity}

      borderpx = 2
      focuscolor = ${hexToMango "#${config.lib.stylix.colors.base0D}"}
      bordercolor = ${hexToMango "#${config.lib.stylix.colors.base01}"}
      rootcolor = ${hexToMango "#${config.lib.stylix.colors.base00}"}
      urgentcolor = ${hexToMango "#${config.lib.stylix.colors.base08}"}

      # Animation
      animation_type = zoom
      animation_open_duration = 200
      animation_close_duration = 150
      animation_open_initial_scale = 0.9
      animation_close_initial_scale = 1.0
      animation_fade_in = 1
      animation_fade_out = 1

      # Layout
      default_layout = tile
      master_factor = 0.55
      nmasters = 1
      gappih = 12
      gappiv = 12
      gappoh = 16
      gappov = 16

      # Input
      repeat_rate = 50
      repeat_delay = 300
      natural_scroll = 1
      tap_to_click = 1
      disable_while_typing = 1
      cursor_size = 24
      follow_mouse = 1

      # Key Bindings (macOS-like)
      bind = SUPER, q, killclient
      bind = SUPER, space, spawn, ${pkgs.fuzzel}/bin/fuzzel
      bind = ALT, Return, spawn, ${pkgs.wezterm}/bin/wezterm
      bind = ALT, e, spawn, ${pkgs.nemo}/bin/nemo
      bind = SUPER, r, reload
      bind = SUPER SHIFT, q, quit

      # Window Focus (vim-style)
      bind = ALT, h, focusdir, left
      bind = ALT, j, focusdir, down
      bind = ALT, k, focusdir, up
      bind = ALT, l, focusdir, right

      # Move Windows
      bind = ALT SHIFT, h, swapdir, left
      bind = ALT SHIFT, j, swapdir, down
      bind = ALT SHIFT, k, swapdir, up
      bind = ALT SHIFT, l, swapdir, right

      # Resize Windows
      bind = ALT CTRL, h, resizedir, left, 40
      bind = ALT CTRL, j, resizedir, down, 40
      bind = ALT CTRL, k, resizedir, up, 40
      bind = ALT CTRL, l, resizedir, right, 40

      # Workspaces
      bind = ALT, 1, view, 1
      bind = ALT, 2, view, 2
      bind = ALT, c, view, 3
      bind = ALT SHIFT, e, view, 4
      bind = ALT, m, view, 5
      bind = ALT, Tab, viewnext
      bind = ALT SHIFT, Tab, viewprev

      # Move to Workspace
      bind = ALT CTRL, 1, tag, 1
      bind = ALT CTRL, 2, tag, 2
      bind = ALT CTRL, c, tag, 3
      bind = ALT CTRL SHIFT, e, tag, 4
      bind = ALT CTRL, m, tag, 5

      # Layout Controls
      bind = ALT, t, setlayout, tile
      bind = ALT, a, setlayout, monocle
      bind = ALT, s, setlayout, scroller
      bind = ALT, g, setlayout, grid
      bind = ALT, f, fullscreen
      bind = ALT, v, togglefloating
      bind = SUPER, Tab, focusnext

      # Mouse
      bindm = SUPER, mouse:272, movewindow
      bindm = SUPER, mouse:273, resizewindow

      # Window Rules
      windowrule = float, title:^(Picture-in-Picture)$
      windowrule = float, class:^(pavucontrol)$
      windowrule = float, class:^(1Password)$
      windowrule = float, class:^(nemo)$
      windowrule = tag 3, class:^(discord)$
      windowrule = tag 3, class:^(slack)$
      windowrule = tag 3, class:^(ferdium)$
      windowrule = tag 4, class:^(thunderbird)$
      windowrule = tag 5, class:^(spotify)$
    '';
  };

  programs.waybar = {
    enable = true;
    systemd.enable = false;

    settings.mainBar = {
      layer = "top";
      position = "top";
      height = 32;
      spacing = 0;
      margin-top = 8;
      margin-left = 16;
      margin-right = 16;

      modules-left = [
        "custom/logo"
      ];
      modules-center = [ "custom/workspaces" ];
      modules-right = [
        "pulseaudio"
        "custom/sep"
        "network"
        "custom/sep"
        "cpu"
        "custom/sep"
        "memory"
        "custom/sep"
        "clock"
        "custom/sep"
        "clock#utc"
        "tray"
      ];

      "custom/logo" = {
        format = "";
        tooltip = false;
      };
      "custom/sep" = {
        format = "|";
        tooltip = false;
      };
      "custom/workspaces" = {
        format = "1  2  C  E  M";
        tooltip = false;
      };
      clock = {
        format = "{:%H:%M}";
        tooltip-format = "<tt>{calendar}</tt>";
      };
      "clock#utc" = {
        format = "{:%H:%M UTC}";
        timezone = "UTC";
        tooltip = false;
      };
      cpu = {
        format = "CPU {usage}%";
        interval = 2;
      };
      memory = {
        format = "MEM {percentage}%";
        interval = 2;
      };
      network = {
        format-wifi = "WiFi";
        format-ethernet = "ETH";
        format-disconnected = "OFF";
      };
      pulseaudio = {
        format = "VOL {volume}%";
        format-muted = "MUTE";
        on-click = "${pkgs.pavucontrol}/bin/pavucontrol";
      };
      tray = {
        spacing = 8;
      };
    };

    style = ''
      * { font-family: "${config.sysinit.theme.font.monospace}", monospace; font-size: 12px; min-height: 0; padding: 0; margin: 0; }
      window#waybar { background: #${c semanticColors.background.primary}; color: #${c semanticColors.foreground.primary}; border-radius: 10px; border: 1px solid #${c semanticColors.background.secondary}; }
      #custom-logo, #custom-workspaces, #clock, #cpu, #memory, #network, #pulseaudio, #tray { padding: 0 10px; }
      #custom-logo { color: #${c semanticColors.accent.primary}; font-size: 14px; padding-left: 12px; }
      #custom-sep { color: #${c semanticColors.foreground.muted}; padding: 0 4px; }
      #custom-workspaces { color: #${c semanticColors.foreground.primary}; letter-spacing: 2px; }
      #clock { color: #${c semanticColors.foreground.primary}; }
      #clock.utc { color: #${c semanticColors.foreground.muted}; }
      #cpu, #memory { color: #${c semanticColors.foreground.muted}; }
      #network { color: #${c semanticColors.semantic.success}; }
      #network.disconnected { color: #${c semanticColors.semantic.error}; }
      #pulseaudio { color: #${c semanticColors.foreground.primary}; }
      #pulseaudio.muted { color: #${c semanticColors.foreground.muted}; }
      #tray { padding: 0 8px; padding-right: 12px; }
      tooltip { background: #${c semanticColors.background.primary}; border: 1px solid #${c semanticColors.accent.primary}; border-radius: 8px; }
      tooltip label { color: #${c semanticColors.foreground.primary}; padding: 4px; }
    '';
  };

  programs.fuzzel = {
    enable = true;
    settings = {
      main = {
        font = "${config.sysinit.theme.font.monospace}:size=12";
        dpi-aware = "no";
        width = 35;
        horizontal-pad = 20;
        vertical-pad = 10;
        inner-pad = 5;
        line-height = 22;
        layer = "overlay";
      };
      colors = {
        background = "${c semanticColors.background.primary}ee";
        text = "${c semanticColors.foreground.primary}ff";
        prompt = "${c semanticColors.accent.primary}ff";
        input = "${c semanticColors.foreground.primary}ff";
        match = "${c semanticColors.accent.primary}ff";
        selection = "${c semanticColors.background.secondary}ff";
        selection-text = "${c semanticColors.foreground.primary}ff";
        selection-match = "${c semanticColors.accent.primary}ff";
        border = "${c semanticColors.accent.primary}ff";
      };
      border = {
        width = 2;
        radius = 10;
      };
    };
  };

  services.mako = {
    enable = true;
    font = "${config.sysinit.theme.font.monospace} 11";
    backgroundColor = semanticColors.background.primary;
    textColor = semanticColors.foreground.primary;
    borderColor = semanticColors.accent.primary;
    borderSize = 2;
    borderRadius = 10;
    padding = "15";
    margin = "10";
    width = 350;
    height = 100;
    defaultTimeout = 5000;
    layer = "overlay";

    extraConfig = ''
      [urgency=low]
      border-color=${semanticColors.foreground.muted}

      [urgency=high]
      border-color=${semanticColors.semantic.error}
      default-timeout=0
    '';
  };

  home.file.".background-image" = {
    source = wallpaper;
    force = true;
  };

  home.file.".local/share/nemo/actions/open-terminal.nemo_action".text = ''
    [Nemo Action]
    Active=true
    Name=Open Terminal Here
    Exec=wezterm -e bash -c "cd %f && bash"
    Selection=Any
    Extensions=any;
  '';

  dconf.settings = {
    "org/cinnamon/desktop/default-applications/terminal".exec = "wezterm";
    "org/nemo/preferences" = {
      show-hidden-files = false;
      show-advanced-permissions = true;
      date-format = "informal";
      default-folder-viewer = "icon-view";
    };
    "org/nemo/window-state" = {
      geometry = "1200x800+50+50";
      sidebar-width = 200;
    };
  };
}
