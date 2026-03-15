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
  # Let stylix auto-theme sway, mako, and GTK.
  # We override rofi because we want a custom layout.
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

      # Input devices
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

      # Wallpaper
      output = {
        "*" = {
          bg = lib.mkForce "${wallpaper} fill";
        };
      };

      # Window appearance — squared corners, no titlebar, minimal border
      window = {
        border = 2;
        titlebar = false;
      };
      floating = {
        border = 2;
        titlebar = false;
      };

      # Colors handled by stylix (sway.enable = true)

      # Floating modifier (Super for mouse move/resize)
      floating.modifier = "Mod4";

      # Autostart
      startup = [
        { command = "dbus-update-activation-environment --systemd --all"; }
        { command = "systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"; }
        { command = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1"; }
        { command = "${pkgs.wl-clipboard}/bin/wl-paste --watch ${pkgs.cliphist}/bin/cliphist store"; }
        { command = "nm-applet --indicator"; }
      ];

      # Window assignment rules
      assigns = {
        "C" = [
          { class = "^discord$"; }
          { class = "^Slack$"; }
          { app_id = "^vesktop$"; }
        ];
        "M" = [
          { class = "^Spotify$"; }
          { app_id = "^spotify$"; }
          { app_id = "^cider$"; }
        ];
      };

      # Floating rules
      window.commands = [
        { command = "floating enable"; criteria = { title = "^Picture-in-Picture$"; }; }
        { command = "floating enable"; criteria = { class = "^pavucontrol$"; }; }
        { command = "floating enable"; criteria = { app_id = "^pavucontrol$"; }; }
        { command = "floating enable"; criteria = { class = "^1Password$"; }; }
        { command = "floating enable"; criteria = { app_id = "^1password$"; }; }
        { command = "floating enable"; criteria = { app_id = "^nemo$"; }; }
        # Opacity: unfocused windows slightly dimmer
        { command = "opacity 0.90"; criteria = { class = ".*"; }; }
        { command = "opacity 0.90"; criteria = { app_id = ".*"; }; }
      ];

      # === Keybindings (matching aerospace) ===
      keybindings = lib.mkOptionDefault {
        # Terminal
        "${mod}+Return" = "exec ${pkgs.wezterm}/bin/wezterm start";

        # App launcher (Super+Space)
        "Mod4+space" = "exec ${pkgs.rofi}/bin/rofi -show drun";

        # Kill window (Super+Q)
        "Mod4+q" = "kill";

        # Exit sway (Super+Ctrl+Q)
        "Mod4+Control+q" = "exec swaymsg exit";

        # Window focus (vim-style)
        "${mod}+h" = "focus left";
        "${mod}+j" = "focus down";
        "${mod}+k" = "focus up";
        "${mod}+l" = "focus right";

        # Resize
        "${mod}+Shift+j" = "resize shrink height 72 px";
        "${mod}+Shift+k" = "resize grow height 72 px";

        # Workspaces (matching aerospace)
        "${mod}+1" = "workspace 1";
        "${mod}+2" = "workspace 2";
        "${mod}+3" = "workspace 3";
        "${mod}+4" = "workspace 4";
        "${mod}+5" = "workspace 5";
        "${mod}+6" = "workspace 6";
        "${mod}+7" = "workspace 7";
        "${mod}+8" = "workspace 8";
        "${mod}+9" = "workspace 9";
        "${mod}+c" = "workspace C";
        "${mod}+m" = "workspace M";

        # Move to workspace (with focus follow)
        "${mod}+Shift+1" = "move container to workspace 1; workspace 1";
        "${mod}+Shift+2" = "move container to workspace 2; workspace 2";
        "${mod}+Shift+3" = "move container to workspace 3; workspace 3";
        "${mod}+Shift+4" = "move container to workspace 4; workspace 4";
        "${mod}+Shift+5" = "move container to workspace 5; workspace 5";
        "${mod}+Shift+6" = "move container to workspace 6; workspace 6";
        "${mod}+Shift+7" = "move container to workspace 7; workspace 7";
        "${mod}+Shift+8" = "move container to workspace 8; workspace 8";
        "${mod}+Shift+9" = "move container to workspace 9; workspace 9";
        "${mod}+Shift+c" = "move container to workspace C; workspace C";
        "${mod}+Shift+m" = "move container to workspace M; workspace M";

        # Workspace cycling
        "${mod}+Tab" = "workspace next_on_output";
        "${mod}+Shift+Tab" = "workspace prev_on_output";

        # Workspace back-and-forth
        "${mod}+p" = "workspace back_and_forth";

        # Fullscreen
        "${mod}+f" = "fullscreen toggle";

        # Float toggle
        "${mod}+v" = "floating toggle";

        # Layout toggle
        "${mod}+t" = "layout toggle split";

        # Enter move mode
        "${mod}+x" = "mode move";

        # Clipboard history
        "Mod4+v" = "exec ${pkgs.cliphist}/bin/cliphist list | ${pkgs.rofi}/bin/rofi -dmenu | ${pkgs.cliphist}/bin/cliphist decode | ${pkgs.wl-clipboard}/bin/wl-copy";

        # Screenshot
        "Print" = "exec ${pkgs.grim}/bin/grim -g \"$(${pkgs.slurp}/bin/slurp)\" ~/Pictures/Screenshots/$(date +%Y-%m-%d_%H-%M-%S).png";

        # Volume (media keys)
        "XF86AudioRaiseVolume" = "exec wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.05+";
        "XF86AudioLowerVolume" = "exec wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.05-";
        "XF86AudioMute" = "exec wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";

        # Media playback
        "XF86AudioPlay" = "exec ${pkgs.playerctl}/bin/playerctl play-pause";
        "XF86AudioPause" = "exec ${pkgs.playerctl}/bin/playerctl play-pause";
        "XF86AudioNext" = "exec ${pkgs.playerctl}/bin/playerctl next";
        "XF86AudioPrev" = "exec ${pkgs.playerctl}/bin/playerctl previous";
      };

      # Modes
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
              border = "#${c.base0D}";
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
      export __NV_DISABLE_EXPLICIT_SYNC=1
    '';
  };

  # === i3status-rust ===
  programs.i3status-rust = {
    enable = true;
    bars = {
      top = {
        theme = "gruvbox-dark";
        icons = "material-nf";
        blocks = [
          {
            block = "focused_window";
            format = " $title.str(max_w:50) |";
          }
          {
            block = "sound";
            format = " $icon $volume |";
            click = [
              {
                button = "left";
                cmd = "${pkgs.pavucontrol}/bin/pavucontrol";
              }
            ];
          }
          {
            block = "net";
            format = " $icon {$ssid $signal_strength |} $ip ";
            missing_format = " 󰖪 down ";
          }
          {
            block = "time";
            interval = 30;
            format = " $icon $timestamp.datetime(f:'%I:%M %p %Z') ";
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

  # === Rofi App Launcher (custom theme) ===
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
      bg:             #${c.base00}cc;
      bg-solid:       #${c.base00};
      bg-selected:    #${c.base01}80;
      fg:             #${c.base06};
      fg-dim:         #${c.base04};
      fg-placeholder: #${c.base03};
      accent:         #${c.base09};
      urgent:         #${c.base08};
      green:          #${c.base0B};
      border-col:     #${c.base02}80;
      none:           transparent;
      font:           "${values.theme.font.monospace} 13";
    }

    window {
      width:           560px;
      border:          1px;
      border-color:    @border-col;
      background-color: @bg;
      padding:         0;
      location:        center;
      anchor:          center;
    }

    mainbox {
      background-color: @none;
      children:        [ inputbar, listview ];
      spacing:         0;
    }

    inputbar {
      background-color: @none;
      children:        [ textbox-prompt, entry ];
      padding:         16px 20px;
      spacing:         12px;
    }

    textbox-prompt {
      expand:          false;
      str:             "";
      font:            "Symbols Nerd Font Mono 15";
      text-color:      @accent;
      background-color: @none;
      vertical-align:  0.5;
    }

    entry {
      background-color: @none;
      text-color:      @fg;
      padding:         8px 0;
      placeholder:     "Type to search...";
      placeholder-color: @fg-placeholder;
      font:            @font;
    }

    listview {
      background-color: @none;
      columns:         1;
      lines:           8;
      padding:         0 8px 8px 8px;
      spacing:         2px;
      fixed-height:    true;
      cycle:           false;
    }

    element {
      background-color: @none;
      text-color:      @fg;
      padding:         10px 14px;
      spacing:         12px;
    }

    element selected.normal {
      background-color: @bg-selected;
      text-color:      @fg;
    }

    element-icon {
      size:            22px;
      background-color: inherit;
    }

    element-text {
      background-color: inherit;
      text-color:      inherit;
      font:            @font;
      vertical-align:  0.5;
    }
  '';

  # === GTK / Icon / Cursor / Theme ===
  gtk = {
    enable = true;
    theme = {
      name = lib.mkForce "Gruvbox-Dark";
      package = lib.mkForce pkgs.gruvbox-gtk-theme;
    };
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
      "image/gif" = "imv.desktop";
      "video/mp4" = "mpv.desktop";
      "audio/mpeg" = "mpv.desktop";
      "inode/directory" = "nemo.desktop";
    };
  };

  # === USB Auto-Mount ===
  services.udiskie = {
    enable = true;
    automount = true;
    notify = true;
    tray = "never";
  };

  # === Nemo File Manager ===
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
      gtk-theme = lib.mkForce "Gruvbox-Dark";
      icon-theme = lib.mkForce "Papirus-Dark";
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
