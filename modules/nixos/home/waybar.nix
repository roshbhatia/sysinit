# Waybar status bar for niri
{
  pkgs,
  values,
  ...
}:

{
  programs.waybar = {
    enable = true;
    systemd.enable = false; # launched by niri spawn-at-startup

    settings.mainBar = {
      layer = "top";
      position = "top";
      height = 34;
      margin-top = 6;
      margin-left = 8;
      margin-right = 8;
      spacing = 0;
      reload_style_on_change = true;

      modules-left = [
        "niri/workspaces"
      ];
      modules-center = [
        "niri/window"
      ];
      modules-right = [
        "pulseaudio"
        "network"
        "cpu"
        "memory"
        "clock"
        "tray"
      ];

      "niri/workspaces" = {
        format = "{icon}";
        format-icons = {
          active = "●";
          default = "○";
        };
      };

      "niri/window" = {
        format = "{title}";
        icon = true;
        icon-size = 16;
        rewrite = {
          "(.*) — Mozilla Firefox" = "$1";
          "(.*) - wezterm" = "$1";
          "(.*) — (.*)$" = "$1";
        };
      };

      clock = {
        format = "{:%I:%M %p}";
        format-alt = "{:%Y-%m-%d %H:%M UTC}";
        tooltip-format = "<tt>{calendar}</tt>";
        timezone = "America/Los_Angeles";
      };

      cpu = {
        format = "  {usage}%";
        interval = 5;
      };

      memory = {
        format = "  {percentage}%";
        interval = 5;
      };

      network = {
        format-wifi = "  {essid}";
        format-ethernet = "󰈁";
        format-disconnected = "󰖪";
        tooltip-format = "{ifname}: {ipaddr}/{cidr}";
      };

      pulseaudio = {
        format = "{icon} {volume}%";
        format-muted = "󰸈 muted";
        format-icons = {
          default = [ "󰕿" "󰖀" "󰕾" ];
        };
        on-click = "${pkgs.pavucontrol}/bin/pavucontrol";
      };

      tray = {
        spacing = 8;
        icon-size = 16;
      };
    };

    style = ''
      * {
        font-family: "${values.theme.font.monospace}", "Symbols Nerd Font Mono", monospace;
        font-size: 12px;
        min-height: 0;
      }

      window#waybar {
        background-color: transparent;
        color: #ebdbb2;
      }

      window#waybar > box {
        background-color: #1d2021;
        border-radius: 10px;
        border: 1px solid #3c383680;
        padding: 0 4px;
      }

      tooltip {
        background-color: #282828;
        border: 1px solid #504945;
        border-radius: 8px;
        color: #ebdbb2;
      }

      /* ── Workspaces ── */
      #workspaces {
        padding: 0 4px;
      }

      #workspaces button {
        color: #504945;
        padding: 0 6px;
        border-radius: 6px;
        background: transparent;
        border: none;
        transition: all 0.15s ease;
      }

      #workspaces button.active {
        color: #fe8019;
      }

      #workspaces button.focused {
        color: #fabd2f;
        background-color: #3c383660;
      }

      #workspaces button:hover {
        color: #ebdbb2;
        background-color: #3c383640;
      }

      /* ── Window Title ── */
      #window {
        color: #a89984;
        padding: 0 12px;
      }

      window#waybar.empty #window {
        background-color: transparent;
        padding: 0;
      }

      /* ── Right modules ── */
      #clock,
      #cpu,
      #memory,
      #network,
      #pulseaudio,
      #tray {
        padding: 0 8px;
        color: #928374;
      }

      #clock {
        color: #ebdbb2;
      }

      #pulseaudio {
        color: #d3869b;
      }

      #network {
        color: #83a598;
      }

      #cpu {
        color: #8ec07c;
      }

      #memory {
        color: #d3869b;
      }

      #tray {
        padding: 0 4px;
      }

      #tray > .passive {
        -gtk-icon-effect: dim;
      }

      #tray > .needs-attention {
        -gtk-icon-effect: highlight;
      }
    '';
  };
}
