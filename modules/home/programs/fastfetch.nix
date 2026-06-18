{
  config,
  pkgs,
  lib,
  values ? null,
  osConfig ? null,
  ...
}:

let
  colors = config.lib.stylix.colors;

  sgr =
    base:
    "38;2;${toString colors."${base}-rgb-r"};${toString colors."${base}-rgb-g"};${
      toString colors."${base}-rgb-b"
    }";

  cTitle = sgr "base05";
  cHardware = sgr "base08";
  cFirmware = sgr "base09";
  cSoftware = sgr "base0F";
  cTheme = sgr "base0E";
  cNetwork = sgr "base0D";
  cSeparator = sgr "base03";
  cLogo = sgr "base0D";

  # Prefer the flake-provided hostname: `networking.hostName` is unset on
  # MDM-managed hosts, so it is not a reliable key for the art lookup.
  hostName =
    if values != null && values ? hostname then
      values.hostname
    else if osConfig != null then
      osConfig.networking.hostName or "unknown"
    else
      config.networking.hostName or "unknown";

  artByHost = {
    lv426 = "rosh";
    Roshan-Bhatia-MacBook-Pro = "laurel";
    arrakis = "nix";
    nostromo = "nix";
  };
  artName = artByHost.${hostName} or "rosh";

  artFiles = {
    rosh = ./fastfetch/art/rosh.txt;
    "rosh-color" = ./fastfetch/art/rosh-color.txt;
    nix = ./fastfetch/art/nix.txt;
    mgs = ./fastfetch/art/mgs.txt;
    vagabond = ./fastfetch/art/vagabond.txt;
    varre = ./fastfetch/art/varre.txt;
    laurel = ./fastfetch/art/laurel.txt;
  };

  hardwareModules = [
    {
      type = "custom";
      format = "{#1;${cHardware}}󰌢 Hardware{#}";
    }
    {
      type = "host";
      key = "├ Host   ";
      keyColor = cHardware;
    }
    {
      type = "cpu";
      key = "├ CPU    ";
      keyColor = cHardware;
    }
    {
      type = "gpu";
      key = "├ GPU    ";
      keyColor = cHardware;
      format = "{name} ({core-count}) @ {frequency}";
    }
    {
      type = "memory";
      key = "├ Memory ";
      keyColor = cHardware;
    }
    {
      type = "disk";
      key = "├ Disk   ";
      keyColor = cHardware;
      folders = "/";
      format = "{size-used} / {size-total} ({size-percentage})";
    }
    {
      type = "swap";
      key = "├ Swap   ";
      keyColor = cHardware;
    }
    {
      type = "display";
      key = "├ Display";
      keyColor = cHardware;
      format = "{scaled-width}x{scaled-height} in {inch}\", {refresh-rate} Hz [{type}]{?is-primary} *{?}";
    }
    {
      type = "battery";
      key = "└ Charge ";
      keyColor = cHardware;
    }
  ];

  firmwareModules = [
    {
      type = "custom";
      format = "{#1;${cFirmware}}󰀵 Firmware{#}";
    }
    {
      type = "os";
      key = "├ OS    ";
      keyColor = cFirmware;
    }
    {
      type = "kernel";
      key = "├ Kernel";
      keyColor = cFirmware;
    }
    {
      type = "uptime";
      key = "└ Uptime";
      keyColor = cFirmware;
    }
  ];

  darwinPackagesText = "printf '%s (brew), %s (brew-cask), %s (mas)' \"$(ls -1 /opt/homebrew/Cellar 2>/dev/null | wc -l | tr -d ' ')\" \"$(ls -1 /opt/homebrew/Caskroom 2>/dev/null | wc -l | tr -d ' ')\" \"$(mas list 2>/dev/null | wc -l | tr -d ' ')\"";

  linuxPackagesText = "printf '%s (nix-store)' \"$(nix-store -q --requisites /run/current-system 2>/dev/null | wc -l | tr -d ' ')\"";

  darwinWmText = "pgrep -xq AeroSpace && echo \"AeroSpace $(aerospace --version 2>/dev/null | head -1 | awk '{print $5}')\" || echo 'Quartz Compositor'";

  linuxWmText = "echo \"\${XDG_CURRENT_DESKTOP:-\${DESKTOP_SESSION:-unknown}}\"";

  softwareModules = [
    {
      type = "custom";
      format = "{#1;${cSoftware}}󰏗 Software{#}";
    }
  ]
  ++ lib.optionals pkgs.stdenv.isDarwin [
    {
      type = "command";
      key = "├ Packages";
      keyColor = cSoftware;
      text = darwinPackagesText;
    }
  ]
  ++ lib.optionals pkgs.stdenv.isLinux [
    {
      type = "command";
      key = "├ Packages";
      keyColor = cSoftware;
      text = linuxPackagesText;
    }
  ]
  ++ [
    {
      type = "shell";
      key = "├ Shell   ";
      keyColor = cSoftware;
    }
    {
      type = "terminal";
      key = "├ Terminal";
      keyColor = cSoftware;
    }
  ]
  ++ lib.optionals pkgs.stdenv.isDarwin [
    {
      type = "command";
      key = "└ WM      ";
      keyColor = cSoftware;
      text = darwinWmText;
    }
  ]
  ++ lib.optionals pkgs.stdenv.isLinux [
    {
      type = "command";
      key = "└ WM      ";
      keyColor = cSoftware;
      text = linuxWmText;
    }
  ];

  themeModules = [
    {
      type = "custom";
      format = "{#1;${cTheme}}󰏘 Theme{#}";
    }
  ]
  ++ lib.optionals pkgs.stdenv.isDarwin [
    {
      type = "command";
      key = "├ OS     ";
      keyColor = cTheme;
      text = "defaults read -g AppleInterfaceStyle &>/dev/null && echo 'dark' || echo 'light'";
    }
  ]
  ++ [
    {
      type = "custom";
      key = "├ Scheme ";
      keyColor = cTheme;
      format = colors.scheme;
    }
    {
      type = "terminalfont";
      key = "└ Font   ";
      keyColor = cTheme;
    }
  ];

  networkModules = [
    {
      type = "custom";
      format = "{#1;${cNetwork}}󰤨 Network{#}";
    }
    {
      type = "publicip";
      key = "├ Public IP";
      keyColor = cNetwork;
      timeout = 1000;
    }
    {
      type = "localip";
      key = "├ Local IP ";
      keyColor = cNetwork;
    }
    {
      type = "dns";
      key = "└ DNS      ";
      keyColor = cNetwork;
    }
  ];

  titleModule = {
    type = "title";
    keyColor = cTitle;
    format = "{#${cTitle}}{user-name}@{host-name}{#}";
  };

  colorsModule = {
    type = "colors";
    paddingLeft = 2;
    symbol = "circle";
  };

  artXdgEntries = lib.mapAttrs' (
    name: path:
    lib.nameValuePair "fastfetch/art/${name}.txt" {
      source = path;
      force = true;
    }
  ) artFiles;
in
{
  programs.fastfetch = {
    enable = true;
    settings = {
      "$schema" = "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json";

      display = {
        separator = " ~> ";
        color = {
          separator = cSeparator;
        };
      };

      logo = {
        type = "file";
        source = "${config.xdg.configHome}/fastfetch/logo.txt";
        color = {
          "1" = cLogo;
        };
        padding = {
          top = 1;
          left = 2;
          right = 2;
        };
      };

      modules = [
        titleModule
        "break"
      ]
      ++ hardwareModules
      ++ [ "break" ]
      ++ firmwareModules
      ++ [ "break" ]
      ++ softwareModules
      ++ [ "break" ]
      ++ themeModules
      ++ [ "break" ]
      ++ networkModules
      ++ [
        "break"
        colorsModule
      ];
    };
  };

  xdg.configFile = artXdgEntries // {
    "fastfetch/logo.txt" = {
      source = artFiles.${artName};
      force = true;
    };
  };
}
