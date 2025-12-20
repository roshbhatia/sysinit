{
  lib,
  values,
  ...
}:

let
  themes = import ../../shared/lib/theme { inherit lib; };
  theme = themes.getTheme values.theme.colorscheme;
  waybarTheme = themes.adapters.waybar.createWaybarTheme theme values.theme;
in
{
  programs.waybar = {
    enable = true;

    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        height = 36;
        spacing = 4;

        modules-left = [
          "hyprland/workspaces"
          "hyprland/window"
        ];

        modules-center = [
          "clock"
        ];

        modules-right = [
          "tray"
          "cpu"
          "memory"
          "temperature"
          "pulseaudio"
          "network"
        ];

        "hyprland/workspaces" = {
          format = "{name}";
          on-click = "activate";
        };

        "hyprland/window" = {
          format = "{}";
          max-length = 50;
        };

        clock = {
          format = "{:%H:%M   %a %b %d}";
          format-alt = "{:%Y-%m-%d}";
          tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
        };

        tray = {
          icon-size = 16;
          spacing = 8;
        };

        cpu = {
          format = " {usage}%";
          tooltip = true;
          interval = 5;
        };

        memory = {
          format = " {used:0.1f}GB";
          tooltip = true;
          interval = 5;
        };

        temperature = {
          format = "󰔏 {temperatureC}°C";
          thermal-zone = 0;
          critical-threshold = 80;
          format-critical = "󰸌 {temperatureC}°C";
        };

        pulseaudio = {
          format = "{icon} {volume}%";
          format-muted = "󰝟";
          format-icons = {
            headphone = "󰋋";
            hands-free = "󰋋";
            headset = "󰋋";
            default = [
              "󰕿"
              "󰖀"
              "󰕾"
            ];
          };
          scroll-step = 1;
          on-click = "pavucontrol";
        };

        network = {
          format-wifi = "󰤨 {signalStrength}%";
          format-ethernet = "󰈀";
          format-disconnected = "󰤭";
          tooltip-format = "{ifname}: {ipaddr}/{cidr}";
          on-click = "nm-connection-editor";
        };
      };
    };

    style = waybarTheme.themeCSS;
  };
}
