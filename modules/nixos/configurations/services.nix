{
  pkgs,
  ...
}:
{
  environment.systemPackages = with pkgs; [
    pulseaudio
  ];

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
    wireplumber.enable = true;
  };

  security.rtkit.enable = true;

  services.pulseaudio.enable = false;

  hardware.bluetooth.enable = true;
  services.blueman.enable = true;

  services = {
    printing.enable = true;
    geoclue2.enable = true;

    udev.packages = with pkgs; [
      gnome-settings-daemon
    ];

    keyd = {
      enable = true;
      keyboards.default.settings = {
        main = {
          capslock = "overload(control, esc)";
          esc = "capslock";
        };
      };
    };

    xrdp = {
      enable = true;
      defaultWindowManager = "niri";
      openFirewall = true;
    };
  };
}
