{
  config,
  lib,
  pkgs,
  ...
}:

let
  themeLib = import ../../shared/theme-colors.nix { inherit lib; };
  themeColors = themeLib.colorsOf config;
  c = themeColors;
  mod = "Mod1";

  wallpaper = pkgs.fetchurl {
    url = "https://wallpapercave.com/wp/wp12329549.png";
    sha256 = "sha256-9R3cDgd1VslCF6mG6jBO64MEdRjCGzWE4m/dAjEixzk=";
  };

  renderTemplate =
    path: variables:
    let
      names = builtins.attrNames variables;
    in
    builtins.replaceStrings (map (name: "@${name}@") names) (map (
      name: toString variables.${name}
    ) names) (builtins.readFile path);

  renderCssTemplate =
    path: variables:
    let
      names = builtins.attrNames variables;
    in
    builtins.replaceStrings (map (name: "__${name}__") names) (map (
      name: toString variables.${name}
    ) names) (builtins.readFile path);

  swayBackgroundName = "sysinit-sway-background";
  swayBackground = pkgs.writeTextFile {
    name = swayBackgroundName;
    destination = "/bin/${swayBackgroundName}";
    executable = true;
    text = renderTemplate ./desktop/sway-background.sh.tmpl {
      swaymsg = "${pkgs.sway}/bin/swaymsg";
    };
  };
  swayBackgroundCommand = lib.escapeShellArgs [
    "${swayBackground}/bin/${swayBackgroundName}"
    "${config.home.homeDirectory}/.background-image"
    (toString wallpaper)
  ];

  waybarAgentSessionsFilter = pkgs.writeText "waybar-agent-sessions.jq" (
    builtins.readFile ./desktop/waybar-agent-sessions.jq
  );
  waybarAgentSessionsName = "sysinit-waybar-agent-sessions";
  waybarAgentSessions = pkgs.writeTextFile {
    name = waybarAgentSessionsName;
    destination = "/bin/${waybarAgentSessionsName}";
    executable = true;
    text = renderTemplate ./desktop/waybar-agent-sessions.sh.tmpl {
      agentSessions = "${pkgs.sysinit-utils}/bin/agent-sessions";
      filter = waybarAgentSessionsFilter;
      jq = "${pkgs.jq}/bin/jq";
    };
  };

  waybarStyle = renderCssTemplate ./desktop/waybar.css.tmpl {
    inherit (c)
      base00
      base01
      base02
      base03
      base04
      base05
      base08
      base0A
      base0B
      base0D
      ;
    font = config.sysinit.theme.font.monospace;
  };
in
{
  assertions = [
    {
      assertion = !(lib.hasInfix "__base" waybarStyle || lib.hasInfix "__font__" waybarStyle);
      message = "the rendered Waybar stylesheet contains an unresolved template token";
    }
  ];

  wayland = {
    windowManager.sway = {
      enable = true;
      wrapperFeatures.gtk = true;
      checkConfig = false;

      config = {
        modifier = mod;
        terminal = "${pkgs.wezterm}/bin/wezterm start";
        menu = "${pkgs.walker}/bin/walker";

        fonts = {
          names = lib.mkForce [ "${config.sysinit.theme.font.monospace}" ];
          size = lib.mkForce 11.0;
        };

        gaps = {
          inner = 16;
          outer = 200;
          top = 100;
          bottom = 100;
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
            bg = lib.mkForce "#${c.base00} solid_color";
            scale = "1";
          };
        };

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
          { command = "nm-applet --indicator"; }
          {
            command = swayBackgroundCommand;
          }
        ];

        assigns = {
          "C" = [
            { class = "^discord$"; }
            { class = "^Slack$"; }
            { app_id = "^vesktop$"; }
          ];
          "M" = [
            { class = "^Spotify$"; }
            { app_id = "^spotify$"; }
          ];
        };

        window.commands = [
          {
            command = "floating enable";
            criteria = {
              title = "^Picture-in-Picture$";
            };
          }
          {
            command = "floating enable";
            criteria = {
              class = "^pavucontrol$";
            };
          }
          {
            command = "floating enable";
            criteria = {
              app_id = "^pavucontrol$";
            };
          }
          {
            command = "floating enable";
            criteria = {
              class = "^1Password$";
            };
          }
          {
            command = "floating enable";
            criteria = {
              app_id = "^1password$";
            };
          }
          {
            command = "floating enable";
            criteria = {
              app_id = "^nemo$";
            };
          }
          {
            command = "fullscreen enable";
            criteria = {
              app_id = "^gamescope$";
            };
          }
        ];

        keybindings = lib.mkForce {
          "${mod}+Return" = "exec ${pkgs.sysinit-utils}/bin/wezspawn --wezterm ${pkgs.wezterm}/bin/wezterm";

          "Mod4+space" = "exec ${pkgs.walker}/bin/walker";

          "Mod4+Shift+space" = "exec ${pkgs.walker}/bin/walker -m 1password";

          "Mod4+q" = "kill";
          "Mod4+Control+q" = "exec swaymsg exit";

          "Mod4+h" = "move scratchpad";
          "Mod4+m" = "move scratchpad";

          "${mod}+h" = "focus left";
          "${mod}+j" = "focus down";
          "${mod}+k" = "focus up";
          "${mod}+l" = "focus right";

          "${mod}+r" = "mode resize";

          "${mod}+1" = "workspace 1";
          "${mod}+2" = "workspace 2";
          "${mod}+3" = "workspace 3";
          "${mod}+c" = "workspace C";
          "${mod}+m" = "workspace M";

          "${mod}+Shift+1" = "move container to workspace 1; workspace 1";
          "${mod}+Shift+2" = "move container to workspace 2; workspace 2";
          "${mod}+Shift+3" = "move container to workspace 3; workspace 3";
          "${mod}+Shift+c" = "move container to workspace C; workspace C";
          "${mod}+Shift+m" = "move container to workspace M; workspace M";

          "${mod}+Tab" = "workspace next_on_output";
          "${mod}+Shift+Tab" = "workspace prev_on_output";
          "${mod}+p" = "workspace back_and_forth";

          "Control+Shift+Left" = "workspace prev_on_output";
          "Control+Shift+Right" = "workspace next_on_output";

          "${mod}+f" = "fullscreen toggle";

          "${mod}+v" = "floating toggle";
          "${mod}+t" = "layout toggle split";

          "${mod}+x" = "mode move";

          "${mod}+g" = "mode locked";

          "Mod4+Tab" = "exec ${pkgs.walker}/bin/walker -m menus:windows";
          "Mod4+Shift+Tab" = "exec ${pkgs.walker}/bin/walker -m menus:windows";

          "${mod}+Shift+v" = "exec ${pkgs.walker}/bin/walker -m clipboard";

          "Mod4+Shift+c" =
            "exec ${pkgs.hyprpicker}/bin/hyprpicker -a -n && ${pkgs.libnotify}/bin/notify-send \"Color Picker\" \"Hex code copied to clipboard\" -i color-management";

          "Mod4+Shift+3" = "exec ${pkgs.sway-contrib.grimshot}/bin/grimshot --notify savecopy output";
          "Mod4+Shift+4" = "exec ${pkgs.sway-contrib.grimshot}/bin/grimshot --notify savecopy area";
          "Mod4+Shift+5" = "exec ${pkgs.sway-contrib.grimshot}/bin/grimshot --notify savecopy window";
          "Print" = "exec ${pkgs.sway-contrib.grimshot}/bin/grimshot --notify savecopy area";

          "XF86AudioRaiseVolume" = "exec wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.05+";
          "XF86AudioLowerVolume" = "exec wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.05-";
          "XF86AudioMute" = "exec wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
          "Mod4+a" = "exec audio-switcher";

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
            "${mod}+Escape" = "mode default";
          };
          resize = {
            "${mod}+h" = "resize shrink width 72 px";
            "${mod}+j" = "resize grow height 72 px";
            "${mod}+k" = "resize shrink height 72 px";
            "${mod}+l" = "resize grow width 72 px";
            "${mod}+Escape" = "mode default";
          };
          locked = {
            "${mod}+Escape" = "mode default";
          };
        };

        bars = [ ];
      };

      extraSessionCommands = ''
        export NIXOS_OZONE_WL=1
        export GDK_BACKEND=wayland
        export QT_QPA_PLATFORM=wayland
        export MOZ_ENABLE_WAYLAND=1
      '';

      extraConfig = builtins.readFile ./desktop/swayfx.conf;
    };
  };

  programs = {
    waybar = {
      enable = true;
      systemd.enable = true;

      settings = [
        {
          layer = "top";
          position = "top";
          height = 32;
          spacing = 0;

          modules-left = [
            "custom/logo"
            "sway/mode"
            "sway/window"
            "custom/agent-sessions"
          ];
          modules-center = [ "sway/workspaces" ];
          modules-right = [
            "clock"
            "battery"
            "pulseaudio"
          ];

          "custom/logo" = {
            format = "󱄅";
            tooltip = false;
          };

          "custom/agent-sessions" = {
            interval = 2;
            return-type = "json";
            exec = "${waybarAgentSessions}/bin/${waybarAgentSessionsName}";
          };

          "sway/mode" = {
            format = "{}";
          };

          "sway/window" = {
            max-length = 40;
            tooltip = false;
          };

          "sway/workspaces" = {
            disable-scroll = true;
            all-outputs = true;
            format = "{name}";
            persistent-workspaces = {
              "1" = [ ];
              "2" = [ ];
              "3" = [ ];
              "C" = [ ];
              "M" = [ ];
            };
          };

          clock = {
            format = "  {:%I:%M %p %Z}";
            format-alt = "󰖟  {:%H:%M UTC}";
            tooltip-format = "{:%A, %B %d, %Y}";
          };

          battery = {
            format = "{icon}  {capacity}%";
            format-charging = "󰂅  {capacity}%";
            format-icons = [
              "󰁺"
              "󰁻"
              "󰁽"
              "󰁿"
              "󰂁"
            ];
            states = {
              warning = 30;
              critical = 15;
            };
          };

          pulseaudio = {
            format = "{icon}  {volume}%";
            format-muted = "󰝟  muted";
            format-icons = {
              default = [
                "󰕿"
                "󰖀"
                "󰕾"
              ];
            };
            on-click = "audio-switcher";
            on-click-right = "${pkgs.pavucontrol}/bin/pavucontrol";
            on-click-middle = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
            scroll-step = 5;
          };
        }
      ];

      style = waybarStyle;
    };
  };

  home = {
    shellAliases = {
      pbcopy = "wl-copy";
      pbpaste = "wl-paste";
    };
    pointerCursor = {
      enable = true;
      name = "macOS";
      package = pkgs.apple-cursor;
      size = 16;
      gtk.enable = true;
    };
    file.".local/share/nemo/actions/open-terminal.nemo_action".source =
      ./desktop/open-terminal.nemo_action;
  };

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
