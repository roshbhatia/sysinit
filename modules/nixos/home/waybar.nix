{
  config,
  lib,
  pkgs,
  values,
  ...
}:

let
  themes = import ../../../../shared/lib/theme { inherit lib; };

  validatedTheme = themes.validateThemeConfig values.theme;
  theme = themes.getTheme validatedTheme.colorscheme;

  waybarAdapter = themes.adapters.waybar;
  waybarThemeConfig = waybarAdapter.createWaybarTheme theme validatedTheme;
in
{
  programs.waybar = {
    enable = true;

    settings = {
      mainBar = {
        position = "top";
        height = 40;
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
          "clock"
        ];

        "hyprland/workspaces" = {
          format = "{name}";
          format-icons = {
            "1" = "";
            "2" = "";
            "3" = "";
            "C" = "";
            "M" = "";
            "S" = "";
            "E" = "";
            default = "";
          };
          on-click = "activate";
          active-only = false;
          all-outputs = true;
          persistent-workspaces = {
            "1" = [ ];
            "2" = [ ];
            "3" = [ ];
            "C" = [ ];
            "M" = [ ];
            "S" = [ ];
            "E" = [ ];
          };
        };

        "hyprland/window" = {
          format = "{}";
          max-length = 50;
          separate-outputs = false;
        };

        clock = {
          format = "{:%H:%M   %a %b %d}";
          format-alt = "{:%Y-%m-%d}";
          on-click-right = "timedatectl set-ntp true";
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
          hwmon-path = "/sys/class/hwmon/hwmon0/temp1_input";
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
      };
    };

    style = waybarThemeConfig.themeCSS;
  };
}
