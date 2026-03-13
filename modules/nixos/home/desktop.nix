# NixOS desktop home-manager configuration: mangowc, waybar, fuzzel, mako, nemo
{
  config,
  lib,
  pkgs,
  values,
  ...
}:

let
  c = color: lib.removePrefix "#" color;
  hexToMango = color: "0x${c color}ff";
  hexToMangoAlpha = color: alpha: "0x${c color}${alpha}";
  
  opacity = values.theme.transparency.opacity or 0.8;

  # Extract colors from Stylix for semantic color mapping
  colors = config.lib.stylix.colors;

  semanticColors = {
    background = {
      primary = "#${colors.base00}";
      secondary = "#${colors.base01}";
    };
    foreground = {
      primary = "#${colors.base05}";
      secondary = "#${colors.base04}";
      muted = "#${colors.base03}";
    };
    accent = {
      primary = "#${colors.base0D}";
      secondary = "#${colors.base0C}";
    };
    semantic = {
      error = "#${colors.base08}";
      success = "#${colors.base0B}";
    };
  };

  wallpaper = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/diinki/linux-retroism/main/wallpapers/copyleft.png";
    sha256 = "1vjf8dq4dzbym9a5sk29cfbr83mlz5manx6n9hq2jkaniw3yvxax";
  };
in
{
  # Disable Stylix for apps using custom theming
  stylix.targets = {
    waybar.enable = false;
    fuzzel.enable = false;
    mako.enable = false;
  };

  # === Mangowc Window Manager ===
  wayland.windowManager.mango = {
    enable = true;
    systemd.enable = true;

    autostart_sh = ''
      # Wait for session target to be fully active
      sleep 2
      ${pkgs.swww}/bin/swww-daemon &
      sleep 1
      ${pkgs.swww}/bin/swww img $HOME/.background-image --transition-type fade --transition-duration 1
    '';

    settings = ''
      # Visual Effects (Retro: Disabled for stability and aesthetic)
      blur = 0
      blur_layer = 0
      blur_optimized = 0
      shadows = 0
      layer_shadows = 0

      border_radius = 0
      no_radius_when_single = 1
      focused_opacity = 1.0
      unfocused_opacity = 1.0

      borderpx = 1
      focuscolor = ${hexToMango "#${colors.base0D}"}
      bordercolor = ${hexToMango "#${colors.base01}"}
      rootcolor = ${hexToMango "#${colors.base00}"}
      urgentcolor = ${hexToMango "#${colors.base08}"}

      # Animation (Disabled for retro feel and NVIDIA stability)
      animation_type = none

      # Layout (Retro: Flush windows)
      default_layout = tile
      master_factor = 0.55
      nmasters = 1
      gappih = 0
      gappiv = 0
      gappoh = 0
      gappov = 0

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
      bind = SUPER, space, spawn, fuzzel
      bind = ALT, Return, spawn, wezterm
      bind = ALT, e, spawn, nemo
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

  # === Waybar Status Bar ===
  programs.waybar = {
    enable = true;
    systemd.enable = false;

    settings.mainBar = {
      layer = "top";
      position = "top";
      exclusive = true;
      passthrough = false;
      height = 28;
      spacing = 0;
      margin-top = 0;
      margin-left = 0;
      margin-right = 0;

      modules-left = [ "custom/logo" "custom/sep" "wlr/workspaces" ];
      modules-center = [ ];
      modules-right = [
        "pulseaudio"
        "network"
        "cpu"
        "memory"
        "clock"
        "clock#utc"
        "tray"
      ];

      "custom/logo" = { format = "  "; tooltip = false; };
      "custom/sep" = { format = "|"; tooltip = false; };
      "wlr/workspaces" = {
        format = "{name}";
        on-click = "activate";
      };
      clock = { format = "{:%H:%M}"; tooltip-format = "<tt>{calendar}</tt>"; };
      "clock#utc" = { format = "{:%H:%M UTC}"; timezone = "UTC"; tooltip = false; };
      cpu = { format = " CPU {usage}% "; interval = 2; };
      memory = { format = " MEM {percentage}% "; interval = 2; };
      network = { format-wifi = " WiFi "; format-ethernet = " ETH "; format-disconnected = " OFF "; };
      pulseaudio = { format = " VOL {volume}% "; format-muted = " MUTE "; on-click = "${pkgs.pavucontrol}/bin/pavucontrol"; };
      tray = { spacing = 8; };
    };

    style = ''
      * { font-family: "${values.theme.font.monospace}", monospace; font-size: 13px; min-height: 0; padding: 0; margin: 0; }
      window#waybar { 
        background: #${colors.base00}; 
        color: #000000; 
        border-bottom: 2px solid #000000;
      }
      #custom-logo, #wlr-workspaces, #clock, #cpu, #memory, #network, #pulseaudio, #tray { 
        padding: 0 6px; 
        margin: 2px 2px;
        border: 2px solid;
        border-top-color: #ffffff;
        border-left-color: #ffffff;
        border-right-color: #808080;
        border-bottom-color: #808080;
        background: #cccccc;
      }
      #custom-logo { color: #000000; font-weight: bold; border: none; background: transparent; }
      #custom-sep { color: #808080; padding: 0 2px; }
      #clock { font-weight: bold; }
      #wlr-workspaces button {
        padding: 0 4px;
        color: #000000;
      }
      #wlr-workspaces button.focused {
        background: #000080;
        color: #ffffff;
        border-top-color: #000000;
        border-left-color: #000000;
        border-right-color: #ffffff;
        border-bottom-color: #ffffff;
      }
      tooltip { background: #${colors.base00}; border: 2px solid #000000; border-radius: 0; }
      tooltip label { color: #000000; padding: 4px; }
    '';
  };

  # === Fuzzel App Launcher ===
  programs.fuzzel = {
    enable = true;
    settings = {
      main = {
        font = "${values.theme.font.monospace}:size=12";
        dpi-aware = "no";
        width = 35;
        horizontal-pad = 20;
        vertical-pad = 10;
        inner-pad = 5;
        line-height = 22;
        layer = "overlay";
      };
      colors = {
        background = "ccccccff";
        text = "000000ff";
        prompt = "000080ff";
        input = "000000ff";
        match = "000080ff";
        selection = "000080ff";
        selection-text = "ffffffff";
        selection-match = "ffffffff";
        border = "000000ff";
      };
      border = { width = 2; radius = 0; };
    };
  };

  # === Mako Notifications ===
  services.mako = {
    enable = true;
    settings = {
      font = "${values.theme.font.monospace} 11";
      background-color = "#cccccc";
      text-color = "#000000";
      border-color = "#000000";
      border-size = 2;
      border-radius = 0;
      padding = "15";
      margin = "10";
      width = 350;
      height = 100;
      default-timeout = 5000;
      layer = "overlay";
    };

    extraConfig = ''
      [urgency=low]
      border-color=#${colors.base03}

      [urgency=high]
      border-color=#${colors.base08}
      default-timeout=0
    '';
  };

  # === Wallpaper ===
  home.file.".background-image" = {
    source = wallpaper;
    force = true;
  };

  # === Nemo File Manager ===
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
