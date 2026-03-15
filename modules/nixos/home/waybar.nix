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
    systemd.enable = false; # niri spawns waybar directly

    settings.mainBar = {
      layer = "top";
      position = "top";
      height = 34;
      "margin-top" = 6;
      "margin-left" = 8;
      "margin-right" = 8;
      spacing = 0;
      reload_style_on_change = true;

      "modules-left" = [
        "niri/window"
      ];
      "modules-center" = [
        "niri/workspaces"
      ];
      "modules-right" = [
        "pulseaudio"
        "network"
        "clock#utc"
        "clock"
      ];

      "niri/workspaces" = {
        format = "{icon}";
        "format-icons" = {
          active = "●";
          default = "○";
        };
      };

      "niri/window" = {
        format = "{}";
        icon = true;
        "icon-size" = 16;
        rewrite = {
          "(.*) — Mozilla Firefox" = "$1";
          "(.*) - wezterm" = "$1";
          "(.*) — (.*)$" = "$1";
        };
      };

      clock = {
        format = "{:%I:%M %p %Z}";
        "tooltip-format" = "<tt>{calendar}</tt>";
      };

      "clock#utc" = {
        format = "{:%H:%M UTC}";
        timezone = "UTC";
        tooltip = false;
      };

      network = {
        "format-wifi" = "  {essid}";
        "format-ethernet" = "󰈁  {ifname}";
        "format-disconnected" = "󰖪  off";
        "tooltip-format" = "{ifname}: {ipaddr}/{cidr}\n{essid} ({signalStrength}%)";
      };

      pulseaudio = {
        format = "{icon}  {volume}%";
        "format-muted" = "󰸈  mute";
        "format-icons" = {
          default = [ "󰕿" "󰖀" "󰕾" ];
        };
        "on-click" = "${pkgs.pavucontrol}/bin/pavucontrol";
        "on-scroll-up" = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 2%+";
        "on-scroll-down" = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 2%-";
        tooltip = false;
      };
    };

    style = ''
      * {
        font-family: "${values.theme.font.monospace}", "Symbols Nerd Font Mono", monospace;
        font-size: 12px;
        min-height: 0;
      }

      /* ── Bar: floating island ── */
      window#waybar {
        background-color: transparent;
        color: #${c.base06};
      }

      window#waybar > box {
        background-color: rgba(${c.base00-rgb-r}, ${c.base00-rgb-g}, ${c.base00-rgb-b}, 0.90);
        border-radius: 8px;
        border: 1px solid rgba(${c.base01-rgb-r}, ${c.base01-rgb-g}, ${c.base01-rgb-b}, 0.3);
        padding: 0 8px;
      }

      tooltip {
        background-color: #${c.base01};
        border: 1px solid #${c.base02};
        border-radius: 6px;
        color: #${c.base06};
      }

      tooltip label {
        color: #${c.base06};
        padding: 4px;
      }

      /* ── Left: window title ── */
      #window {
        color: #${c.base06};
        padding: 0 10px;
        font-size: 12px;
      }

      window#waybar.empty #window {
        background-color: transparent;
        padding: 0;
        min-width: 0;
      }

      /* ── Center: workspaces ── */
      #workspaces {
        padding: 0 4px;
      }

      #workspaces button {
        color: #${c.base03};
        padding: 0 5px;
        margin: 4px 1px;
        border-radius: 6px;
        background: transparent;
        border: none;
      }

      #workspaces button.active {
        color: #${c.base0A};
        background-color: rgba(${c.base01-rgb-r}, ${c.base01-rgb-g}, ${c.base01-rgb-b}, 0.5);
      }

      #workspaces button:hover {
        color: #${c.base06};
        background-color: rgba(${c.base01-rgb-r}, ${c.base01-rgb-g}, ${c.base01-rgb-b}, 0.3);
      }

      /* ── Right modules ── */
      #clock,
      #network,
      #pulseaudio {
        padding: 0 8px;
        margin: 4px 0;
        color: #${c.base04};
      }

      #clock {
        color: #${c.base06};
      }

      #clock.utc {
        color: #${c.base04};
        font-size: 11px;
      }

      #pulseaudio {
        color: #${c.base0E};
      }

      #network {
        color: #${c.base0D};
      }
    '';
  };
}
