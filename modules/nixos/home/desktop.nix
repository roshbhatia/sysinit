# NixOS desktop home-manager configuration: hyprland, waybar, rofi, mako, nemo
{
  config,
  lib,
  pkgs,
  values,
  ...
}:

let
  colors = config.lib.stylix.colors;

  wallpaper = pkgs.fetchurl {
    url = "https://images5.alphacoders.com/759/thumb-1920-759307.jpg";
    sha256 = "0ihk74jv5yrfzqzdsjmiwlsnmdai6gf15pl5hh8nvmvhqndg0x2q";
  };
in
{
  stylix.targets = {
    waybar.enable = false;
    rofi.enable = false;
    mako.enable = false;
    hyprland.enable = false;
  };

  # === Hyprland Window Manager ===
  wayland.windowManager.hyprland = {
    enable = true;
    systemd.enable = true;

    settings = {
      # Environment
      env = [
        "WLR_NO_HARDWARE_CURSORS,1"
        "XDG_CURRENT_DESKTOP,Hyprland"
        "XDG_SESSION_TYPE,wayland"
        "NIXOS_OZONE_WL,1"
        "GDK_BACKEND,wayland"
        "QT_QPA_PLATFORM,wayland"
        "MOZ_ENABLE_WAYLAND,1"
      ];

      # Autostart
      exec-once = [
        "dbus-update-activation-environment --systemd --all"
        "systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"
        "${pkgs.swww}/bin/swww-daemon"
        "sleep 1 && ${pkgs.swww}/bin/swww img $HOME/.background-image --transition-type fade --transition-duration 1"
        "${pkgs.waybar}/bin/waybar"
        "${pkgs.mako}/bin/mako"
        "nm-applet --indicator"
      ];

      # Monitor: auto-detect
      monitor = [ ",preferred,auto,auto" ];

      # Input
      input = {
        kb_layout = "us";
        repeat_rate = 50;
        repeat_delay = 300;
        follow_mouse = 1;
        touchpad = {
          natural_scroll = true;
          tap-to-click = true;
          disable_while_typing = true;
        };
      };

      # General: retro flat aesthetic
      general = {
        layout = "dwindle";
        gaps_in = 0;
        gaps_out = 0;
        border_size = 1;
        "col.active_border" = "rgb(${colors.base0D})";
        "col.inactive_border" = "rgb(${colors.base01})";
        resize_on_border = true;
      };

      dwindle = {
        preserve_split = true;
        force_split = 2;
      };

      # Decoration: retro (no rounding, no blur, classic shadow)
      decoration = {
        rounding = 0;

        blur.enabled = false;

        shadow = {
          enabled = true;
          range = 2;
          render_power = 5;
          color = "rgba(000000d9)";
          offset = "2 2";
        };
      };

      # Animations: disabled for retro feel
      animations.enabled = false;

      # Misc
      misc = {
        disable_hyprland_logo = true;
        disable_splash_rendering = true;
        force_default_wallpaper = 0;
      };

      # Key Bindings
      bind = [
        "SUPER, Q, killactive"
        "SUPER, SPACE, exec, ${pkgs.rofi}/bin/rofi -show drun -theme ~/.config/rofi/config.rasi"
        "ALT, Return, exec, wezterm"
        "ALT, E, exec, nemo"
        "SUPER SHIFT, Q, exit"

        # Window Focus (vim-style)
        "ALT, H, movefocus, l"
        "ALT, J, movefocus, d"
        "ALT, K, movefocus, u"
        "ALT, L, movefocus, r"

        # Move Windows
        "ALT SHIFT, H, movewindow, l"
        "ALT SHIFT, J, movewindow, d"
        "ALT SHIFT, K, movewindow, u"
        "ALT SHIFT, L, movewindow, r"

        # Resize Windows
        "ALT CTRL, H, resizeactive, -40 0"
        "ALT CTRL, J, resizeactive, 0 40"
        "ALT CTRL, K, resizeactive, 0 -40"
        "ALT CTRL, L, resizeactive, 40 0"

        # Workspaces
        "ALT, 1, workspace, 1"
        "ALT, 2, workspace, 2"
        "ALT, 3, workspace, 3"
        "ALT, 4, workspace, 4"
        "ALT, 5, workspace, 5"
        "ALT, Tab, workspace, e+1"
        "ALT SHIFT, Tab, workspace, e-1"

        # Move to Workspace
        "ALT CTRL, 1, movetoworkspace, 1"
        "ALT CTRL, 2, movetoworkspace, 2"
        "ALT CTRL, 3, movetoworkspace, 3"
        "ALT CTRL, 4, movetoworkspace, 4"
        "ALT CTRL, 5, movetoworkspace, 5"

        # Layout Controls
        "ALT, F, fullscreen"
        "ALT, V, togglefloating"
        "SUPER, Tab, cyclenext"
      ];

      # Mouse bindings
      bindm = [
        "SUPER, mouse:272, movewindow"
        "SUPER, mouse:273, resizewindow"
      ];

      # Window Rules
      windowrulev2 = [
        "float, title:^(Picture-in-Picture)$"
        "float, class:^(pavucontrol)$"
        "float, class:^(1Password)$"
        "float, class:^(nemo)$"
        "workspace 3, class:^(discord)$"
        "workspace 3, class:^(slack)$"
        "workspace 3, class:^(ferdium)$"
        "workspace 4, class:^(thunderbird)$"
        "workspace 5, class:^(spotify)$"
      ];
    };
  };

  # === Rofi App Launcher ===
  xdg.configFile."rofi/config.rasi".text = ''
    configuration {
      modi: "drun,run,window";
      show-icons: true;
      terminal: "wezterm";
      drun-display-format: "{icon} {name}";
      disable-history: false;
      hide-scrollbar: true;
      sorting-method: "fzf";
    }

    * {
      bg:          #cccccc;
      bg-light:    #d8d8d8;
      border-col:  #000000;
      selected:    #000080;
      fg:          #000000;
      fg-light:    #ffffff;
    }

    window {
      width: 400px;
      border: 2px;
      border-color: @border-col;
      background-color: @bg;
      border-radius: 0px;
    }

    mainbox {
      background-color: @bg;
      children: [ inputbar, listview ];
    }

    inputbar {
      background-color: @bg;
      children: [ prompt, entry ];
      padding: 6px;
      border: 0 0 2px 0;
      border-color: @border-col;
    }

    prompt {
      background-color: @selected;
      text-color: @fg-light;
      padding: 4px 8px;
      font: "${values.theme.font.monospace} 12";
    }

    entry {
      background-color: @bg-light;
      text-color: @fg;
      padding: 4px 8px;
      placeholder: "Search...";
      font: "${values.theme.font.monospace} 12";
      border: 2px solid;
      border-color: #808080 #ffffff #ffffff #808080;
    }

    listview {
      background-color: @bg;
      columns: 1;
      lines: 8;
      padding: 4px;
      spacing: 2px;
    }

    element {
      background-color: @bg;
      text-color: @fg;
      padding: 4px 8px;
      border-radius: 0px;
    }

    element selected {
      background-color: @selected;
      text-color: @fg-light;
    }

    element-icon {
      size: 20px;
      background-color: inherit;
    }

    element-text {
      background-color: inherit;
      text-color: inherit;
      font: "${values.theme.font.monospace} 12";
    }
  '';

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

      modules-left = [
        "custom/logo"
        "custom/sep"
        "hyprland/workspaces"
      ];
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

      "custom/logo" = {
        format = "  ";
        tooltip = false;
      };
      "custom/sep" = {
        format = "|";
        tooltip = false;
      };
      "hyprland/workspaces" = {
        format = "{name}";
        on-click = "activate";
        sort-by-number = true;
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
        format = " CPU {usage}% ";
        interval = 2;
      };
      memory = {
        format = " MEM {percentage}% ";
        interval = 2;
      };
      network = {
        format-wifi = " WiFi ";
        format-ethernet = " ETH ";
        format-disconnected = " OFF ";
      };
      pulseaudio = {
        format = " VOL {volume}% ";
        format-muted = " MUTE ";
        on-click = "${pkgs.pavucontrol}/bin/pavucontrol";
      };
      tray = {
        spacing = 8;
      };
    };

    style = ''
      * { font-family: "${values.theme.font.monospace}", monospace; font-size: 13px; min-height: 0; padding: 0; margin: 0; }
      window#waybar {
        background: #${colors.base00};
        color: #000000;
        border-bottom: 2px solid #000000;
      }
      #custom-logo, #workspaces, #clock, #cpu, #memory, #network, #pulseaudio, #tray {
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
      #workspaces button {
        padding: 0 4px;
        color: #000000;
      }
      #workspaces button.active {
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
