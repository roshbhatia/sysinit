{
  ...
}:

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

        # Hyprland workspaces module
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

        # Active window title
        "hyprland/window" = {
          format = "{}";
          max-length = 50;
          separate-outputs = false;
        };

        # Clock module
        clock = {
          format = "{:%H:%M   %a %b %d}";
          format-alt = "{:%Y-%m-%d}";
          on-click-right = "timedatectl set-ntp true";
          tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
        };

        # System tray
        tray = {
          icon-size = 16;
          spacing = 8;
        };

        # CPU monitoring
        cpu = {
          format = " {usage}%";
          tooltip = true;
          interval = 5;
        };

        # Memory monitoring
        memory = {
          format = " {used:0.1f}GB";
          tooltip = true;
          interval = 5;
        };

        # Temperature monitoring
        temperature = {
          format = "󰔏 {temperatureC}°C";
          thermal-zone = 0;
          hwmon-path = "/sys/class/hwmon/hwmon0/temp1_input";
          critical-threshold = 80;
          format-critical = "󰸌 {temperatureC}°C";
        };

        # Pulseaudio (for NVIDIA audio if available)
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

    # Waybar styling
    style = builtins.readFile ./style.css;
  };
}
