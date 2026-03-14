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
        format = "{}";
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
        format-alt = "{:%a %b %d · %H:%M UTC}";
        tooltip-format = "<tt>{calendar}</tt>";
      };

      cpu = {
        format = "  {usage}%";
        interval = 5;
        tooltip = false;
      };

      memory = {
        format = "  {percentage}%";
        interval = 5;
        tooltip = false;
      };

      network = {
        format-wifi = "  {signalStrength}%";
        format-ethernet = "󰈁  {ifname}";
        format-disconnected = "󰖪  off";
        tooltip-format = "{ifname}: {ipaddr}/{cidr}\n{essid} ({signalStrength}%)";
      };

      pulseaudio = {
        format = "{icon}  {volume}%";
        format-muted = "󰸈  mute";
        format-icons = {
          default = [ "󰕿" "󰖀" "󰕾" ];
        };
        on-click = "${pkgs.pavucontrol}/bin/pavucontrol";
        tooltip = false;
      };

      tray = {
        spacing = 8;
        icon-size = 14;
      };
    };

    style = ''
      * {
        font-family: "${values.theme.font.monospace}", "Symbols Nerd Font Mono", monospace;
        font-size: 12px;
        min-height: 0;
      }

      /* ── Bar frame: floating island ── */
      window#waybar {
        background-color: transparent;
        color: #ebdbb2;
      }

      window#waybar > box {
        background-color: rgba(29, 32, 33, 0.90);
        border-radius: 10px;
        border: 1px solid rgba(60, 56, 54, 0.4);
        padding: 0 6px;
      }

      tooltip {
        background-color: #282828;
        border: 1px solid #504945;
        border-radius: 8px;
        color: #ebdbb2;
      }

      tooltip label {
        color: #ebdbb2;
        padding: 4px;
      }

      /* ── Workspaces ── */
      #workspaces {
        padding: 0 2px;
      }

      #workspaces button {
        color: #504945;
        padding: 0 5px;
        margin: 4px 1px;
        border-radius: 6px;
        background: transparent;
        border: none;
        transition: all 0.2s cubic-bezier(0.25, 0.46, 0.45, 0.94);
      }

      #workspaces button.active {
        color: #fabd2f;
        background-color: rgba(60, 56, 54, 0.5);
      }

      #workspaces button:hover {
        color: #ebdbb2;
        background-color: rgba(60, 56, 54, 0.3);
      }

      /* ── Window Title (center) ── */
      #window {
        color: #a89984;
        padding: 0 14px;
        font-size: 11px;
      }

      window#waybar.empty #window {
        background-color: transparent;
        padding: 0;
        min-width: 0;
      }

      /* ── Right modules: muted by default ── */
      #clock,
      #cpu,
      #memory,
      #network,
      #pulseaudio,
      #battery,
      #tray {
        padding: 0 8px;
        margin: 4px 0;
        color: #928374;
        border-radius: 6px;
        transition: all 0.2s ease;
      }

      /* Clock stands out */
      #clock {
        color: #ebdbb2;
        padding: 0 10px;
      }

      /* Each module gets its own gruvbox accent on hover */
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

      /* Tray */
      #tray {
        padding: 0 6px;
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
