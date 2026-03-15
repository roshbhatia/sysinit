# NixOS desktop home-manager: sway, swaybar + i3status-rust, rofi, mako, nemo
{
  config,
  lib,
  pkgs,
  values,
  ...
}:

let
  c = config.lib.stylix.colors;
  mod = "Mod1"; # Alt key

  wallpaper = pkgs.fetchurl {
    url = "https://wallpapercave.com/wp/wp12329549.png";
    sha256 = "sha256-9R3cDgd1VslCF6mG6jBO64MEdRjCGzWE4m/dAjEixzk=";
  };
in
{
  # Let stylix auto-theme sway colors and mako.
  # Rofi uses custom layout so we override it.
  stylix.targets = {
    sway.enable = true;
    mako.enable = true;
    rofi.enable = false;
  };

  # === Sway Window Manager ===
  wayland.windowManager.sway = {
    enable = true;
    wrapperFeatures.gtk = true;

    config = {
      modifier = mod;
      terminal = "${pkgs.wezterm}/bin/wezterm start";
      menu = "${pkgs.rofi}/bin/rofi -show drun";

      fonts = {
        names = lib.mkForce [ "${values.theme.font.monospace}" ];
        size = lib.mkForce 11.0;
      };

      gaps = {
        inner = 8;
        outer = 0;
      };

      defaultWorkspace = "workspace number 1";

      input = {
        "type:keyboard" = {
          xkb_layout = "us";
          repeat_rate = "50";
          repeat_delay = "300";
        };
        "type:pointer" = {
          accel_profile = "flat";
          pointer_accel = "-0.5";
        };
        "type:touchpad" = {
          natural_scroll = "enabled";
          tap = "enabled";
          dwt = "enabled";
        };
      };

      output = {
        "*" = {
          bg = lib.mkForce "${wallpaper} fill";
        };
      };

      # No titlebar, no border — clean and squared
      window = {
        border = 0;
        titlebar = false;
      };
      floating = {
        border = 1;
        titlebar = false;
      };

      floating.modifier = "Mod4";

      startup = [
        { command = "dbus-update-activation-environment --systemd --all"; }
        { command = "systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"; }
        { command = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1"; }
        { command = "${pkgs.wl-clipboard}/bin/wl-paste --watch ${pkgs.cliphist}/bin/cliphist store"; }
        { command = "nm-applet --indicator"; }
      ];

      assigns = {
        "C" = [
          { class = "^discord$"; }
          { class = "^Slack$"; }
          { app_id = "^vesktop$"; }
        ];
        "E" = [
          { class = "^thunderbird$"; }
        ];
        "M" = [
          { class = "^Spotify$"; }
          { app_id = "^spotify$"; }
          { app_id = "^cider$"; }
        ];
      };

      window.commands = [
        { command = "floating enable"; criteria = { title = "^Picture-in-Picture$"; }; }
        { command = "floating enable"; criteria = { class = "^pavucontrol$"; }; }
        { command = "floating enable"; criteria = { app_id = "^pavucontrol$"; }; }
        { command = "floating enable"; criteria = { class = "^1Password$"; }; }
        { command = "floating enable"; criteria = { app_id = "^1password$"; }; }
        { command = "floating enable"; criteria = { app_id = "^nemo$"; }; }
      ];

      keybindings = lib.mkOptionDefault {
        # Terminal
        "${mod}+Return" = "exec ${pkgs.wezterm}/bin/wezterm start";

        # App launcher
        "Mod4+space" = "exec ${pkgs.rofi}/bin/rofi -show drun";

        # Kill / exit
        "Mod4+q" = "kill";
        "Mod4+Control+q" = "exec swaymsg exit";

        # Focus (vim-style, matching aerospace)
        "${mod}+h" = "focus left";
        "${mod}+j" = "focus down";
        "${mod}+k" = "focus up";
        "${mod}+l" = "focus right";

        # Resize
        "${mod}+Shift+j" = "resize shrink height 72 px";
        "${mod}+Shift+k" = "resize grow height 72 px";

        # Workspaces (only 1, 2, C, E, M — matching aerospace)
        "${mod}+1" = "workspace 1";
        "${mod}+2" = "workspace 2";
        "${mod}+c" = "workspace C";
        "${mod}+e" = "workspace E";
        "${mod}+m" = "workspace M";

        "${mod}+Shift+1" = "move container to workspace 1; workspace 1";
        "${mod}+Shift+2" = "move container to workspace 2; workspace 2";
        "${mod}+Shift+c" = "move container to workspace C; workspace C";
        "${mod}+Shift+e" = "move container to workspace E; workspace E";
        "${mod}+Shift+m" = "move container to workspace M; workspace M";

        # Workspace cycling
        "${mod}+Tab" = "workspace next_on_output";
        "${mod}+Shift+Tab" = "workspace prev_on_output";
        "${mod}+p" = "workspace back_and_forth";

        # Fullscreen
        "${mod}+f" = "fullscreen toggle";

        # Float / layout
        "${mod}+v" = "floating toggle";
        "${mod}+t" = "layout toggle split";

        # Move mode
        "${mod}+x" = "mode move";

        # Clipboard history
        "Mod4+v" = "exec ${pkgs.cliphist}/bin/cliphist list | ${pkgs.rofi}/bin/rofi -dmenu | ${pkgs.cliphist}/bin/cliphist decode | ${pkgs.wl-clipboard}/bin/wl-copy";

        # Screenshot (region select)
        "Print" = "exec ${pkgs.grim}/bin/grim -g \"$(${pkgs.slurp}/bin/slurp)\" ~/Pictures/Screenshots/$(date +%Y-%m-%d_%H-%M-%S).png";

        # Volume
        "XF86AudioRaiseVolume" = "exec wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.05+";
        "XF86AudioLowerVolume" = "exec wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.05-";
        "XF86AudioMute" = "exec wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";

        # Media
        "XF86AudioPlay" = "exec ${pkgs.playerctl}/bin/playerctl play-pause";
        "XF86AudioPause" = "exec ${pkgs.playerctl}/bin/playerctl play-pause";
        "XF86AudioNext" = "exec ${pkgs.playerctl}/bin/playerctl next";
        "XF86AudioPrev" = "exec ${pkgs.playerctl}/bin/playerctl previous";
      };

      modes = {
        move = {
          "${mod}+h" = "move left";
          "${mod}+j" = "move down";
          "${mod}+k" = "move up";
          "${mod}+l" = "move right";
          "Escape" = "mode default";
        };
      };

      # Swaybar + i3status-rust
      bars = [
        {
          position = "top";
          statusCommand = "${pkgs.i3status-rust}/bin/i3status-rs ${config.xdg.configHome}/i3status-rust/config-top.toml";
          fonts = {
            names = [ "${values.theme.font.monospace}" "Symbols Nerd Font Mono" ];
            size = 11.0;
          };
          colors = {
            background = "#${c.base00}";
            statusline = "#${c.base05}";
            separator = "#${c.base02}";
            focusedWorkspace = {
              border = "#${c.base0E}";
              background = "#${c.base01}";
              text = "#${c.base06}";
            };
            activeWorkspace = {
              border = "#${c.base02}";
              background = "#${c.base01}";
              text = "#${c.base05}";
            };
            inactiveWorkspace = {
              border = "#${c.base00}";
              background = "#${c.base00}";
              text = "#${c.base03}";
            };
            urgentWorkspace = {
              border = "#${c.base08}";
              background = "#${c.base08}";
              text = "#${c.base00}";
            };
          };
        }
      ];
    };

    extraSessionCommands = ''
      export NIXOS_OZONE_WL=1
      export GDK_BACKEND=wayland
      export QT_QPA_PLATFORM=wayland
      export MOZ_ENABLE_WAYLAND=1
    '';

    # SwayFX visual effects
    extraConfig = ''
      # Dim unfocused windows
      default_dim_inactive 0.15

      # Shadows
      shadows enable
      shadow_blur_radius 20
      shadow_color #00000064

      # Corner radius (0 = squared)
      corner_radius 0
    '';
  };

  # === i3status-rust ===
  programs.i3status-rust = {
    enable = true;
    bars = {
      top = {
        theme = "native";
        icons = "material-nf";
        blocks = [
          {
            block = "focused_window";
            format = " $title.str(max_w:48) ";
          }
          {
            block = "sound";
            format = " $icon $volume ";
            click = [
              {
                button = "left";
                cmd = "${pkgs.pavucontrol}/bin/pavucontrol";
              }
            ];
          }
          {
            block = "net";
            format = " $icon $ip ";
            format_alt = " $icon $ssid $signal_strength ";
            missing_format = " 󰖪 ";
          }
          {
            block = "time";
            interval = 30;
            format = " $icon $timestamp.datetime(f:'%I:%M %p') ";
          }
          {
            block = "time";
            interval = 60;
            format = " $timestamp.datetime(f:'%H:%M UTC') ";
            timezone = "UTC";
          }
        ];
      };
    };
  };

  # === Rofi App Launcher ===
  xdg.configFile."rofi/config.rasi".text = ''
    configuration {
      modi: "drun,run,window";
      show-icons: true;
      icon-theme: "Papirus-Dark";
      terminal: "wezterm";
      drun-display-format: "{name}";
      disable-history: false;
      hide-scrollbar: true;
      sorting-method: "fzf";
      click-to-exit: true;

      kb-clear-line: "";
      kb-remove-to-sol: "";
      kb-remove-to-eol: "";
      kb-remove-char-forward: "Delete";
      kb-remove-word-back: "Control+BackSpace";
      kb-accept-entry: "Return,KP_Enter";
      kb-cancel: "Escape,Control+bracketleft";
      kb-row-up: "Up,Control+k,Control+p";
      kb-row-down: "Down,Control+j,Control+n";
      kb-page-prev: "Page_Up,Control+u";
      kb-page-next: "Page_Down,Control+d";
      kb-move-front: "Control+a";
      kb-move-end: "Control+e";
    }

    * {
      font: "${values.theme.font.monospace} 13";
    }

    window {
      width:           520px;
      border:          2px solid;
      border-color:    #${c.base02};
      background-color: #${c.base00};
      padding:         0;
      location:        center;
      anchor:          center;
    }

    mainbox {
      background-color: transparent;
      children:        [ inputbar, listview ];
      spacing:         0;
    }

    inputbar {
      background-color: #${c.base01};
      children:        [ prompt, entry ];
      padding:         12px 16px;
      spacing:         8px;
    }

    prompt {
      background-color: transparent;
      text-color:      #${c.base0E};
      font:            "Symbols Nerd Font Mono 14";
      vertical-align:  0.5;
    }

    entry {
      background-color: transparent;
      text-color:      #${c.base06};
      padding:         4px 0;
      placeholder:     "Search...";
      placeholder-color: #${c.base03};
    }

    listview {
      background-color: transparent;
      columns:         1;
      lines:           10;
      padding:         4px 0;
      spacing:         0;
      fixed-height:    true;
      cycle:           false;
    }

    element {
      background-color: transparent;
      text-color:      #${c.base05};
      padding:         8px 16px;
      spacing:         10px;
    }

    element selected.normal {
      background-color: #${c.base02};
      text-color:      #${c.base06};
    }

    element selected.urgent {
      background-color: #${c.base08};
      text-color:      #${c.base00};
    }

    element selected.active {
      background-color: #${c.base02};
      text-color:      #${c.base0B};
    }

    element normal.urgent {
      text-color:      #${c.base08};
    }

    element normal.active {
      text-color:      #${c.base0B};
    }

    element-icon {
      size:            20px;
      background-color: inherit;
    }

    element-text {
      background-color: inherit;
      text-color:      inherit;
      vertical-align:  0.5;
    }
  '';

  # === GTK / Icon / Cursor ===
  gtk = {
    enable = true;
    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };
    gtk3.extraConfig.gtk-application-prefer-dark-theme = 1;
    gtk4.extraConfig.gtk-application-prefer-dark-theme = 1;
  };

  home.pointerCursor = {
    name = "macOS";
    package = pkgs.apple-cursor;
    size = 16;
    gtk.enable = true;
  };

  # === Wallpaper ===
  home.file.".background-image" = {
    source = wallpaper;
    force = true;
  };

  # === XDG Default Applications ===
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "text/html" = "firefox.desktop";
      "x-scheme-handler/http" = "firefox.desktop";
      "x-scheme-handler/https" = "firefox.desktop";
      "application/pdf" = "org.pwmt.zathura.desktop";
      "image/png" = "imv.desktop";
      "image/jpeg" = "imv.desktop";
      "video/mp4" = "mpv.desktop";
      "audio/mpeg" = "mpv.desktop";
      "inode/directory" = "nemo.desktop";
    };
  };

  # USB Auto-Mount
  services.udiskie = {
    enable = true;
    automount = true;
    notify = true;
    tray = "never";
  };

  # Nemo
  home.file.".local/share/nemo/actions/open-terminal.nemo_action".text = ''
    [Nemo Action]
    Active=true
    Name=Open Terminal Here
    Exec=wezterm start -e bash -c "cd %f && bash"
    Selection=Any
    Extensions=any;
  '';

  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = lib.mkForce "prefer-dark";
    };
    "org/cinnamon/desktop/default-applications/terminal".exec = "wezterm";
    "org/nemo/preferences" = {
      show-hidden-files = false;
      show-advanced-permissions = true;
      date-format = "informal";
      default-folder-viewer = "icon-view";
    };
  };
}
