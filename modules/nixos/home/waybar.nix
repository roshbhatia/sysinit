# Waybar status bar for niri
{
  config,
  pkgs,
  values,
  ...
}:

let
  c = config.lib.stylix.colors;
in
{
  programs.waybar = {
    enable = true;
    systemd.enable = true;

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
        color: #${c.base06};
      }

      window#waybar > box {
        background-color: rgba(${c.base00-rgb-r}, ${c.base00-rgb-g}, ${c.base00-rgb-b}, 0.90);
        border-radius: 10px;
        border: 1px solid rgba(${c.base01-rgb-r}, ${c.base01-rgb-g}, ${c.base01-rgb-b}, 0.4);
        padding: 0 6px;
      }

      tooltip {
        background-color: #${c.base01};
        border: 1px solid #${c.base02};
        border-radius: 8px;
        color: #${c.base06};
      }

      tooltip label {
        color: #${c.base06};
        padding: 4px;
      }

      /* ── Workspaces ── */
      #workspaces {
        padding: 0 2px;
      }

      #workspaces button {
        color: #${c.base02};
        padding: 0 5px;
        margin: 4px 1px;
        border-radius: 6px;
        background: transparent;
        border: none;
        transition: all 0.2s cubic-bezier(0.25, 0.46, 0.45, 0.94);
      }

      #workspaces button.active {
        color: #${c.base0A};
        background-color: rgba(${c.base01-rgb-r}, ${c.base01-rgb-g}, ${c.base01-rgb-b}, 0.5);
      }

      #workspaces button:hover {
        color: #${c.base06};
        background-color: rgba(${c.base01-rgb-r}, ${c.base01-rgb-g}, ${c.base01-rgb-b}, 0.3);
      }

      /* ── Window Title (center) ── */
      #window {
        color: #${c.base04};
        padding: 0 14px;
        font-size: 11px;
      }

      window#waybar.empty #window {
        background-color: transparent;
        padding: 0;
        min-width: 0;
      }

      /* ── Right modules ── */
      #clock,
      #cpu,
      #memory,
      #network,
      #pulseaudio,
      #tray {
        padding: 0 8px;
        margin: 4px 0;
        color: #${c.base04};
        border-radius: 6px;
        transition: all 0.2s ease;
      }

      #clock {
        color: #${c.base06};
        padding: 0 10px;
      }

      #pulseaudio {
        color: #${c.base0E};
      }

      #network {
        color: #${c.base0D};
      }

      #cpu {
        color: #${c.base0C};
      }

      #memory {
        color: #${c.base0E};
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
