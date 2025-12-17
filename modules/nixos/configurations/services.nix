{
  pkgs,
  ...
}:
{
  #============================= Audio(PipeWire) =======================

  environment.systemPackages = with pkgs; [
    pulseaudio # provides `pactl`, which is required by some apps (e.g. sonic-pi)
  ];

  # PipeWire is a low-level multimedia framework for audio and video capture/playback
  # It supports PulseAudio, JACK, ALSA, and GStreamer-based applications
  # Great Bluetooth support makes it a good alternative to PulseAudio
  # https://nixos.wiki/wiki/PipeWire
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
    wireplumber.enable = true;
  };

  # rtkit is optional but recommended for PipeWire
  security.rtkit.enable = true;

  # Disable pulseaudio - it conflicts with pipewire
  services.pulseaudio.enable = false;

  #============================= Bluetooth =============================

  # Enable Bluetooth and GUI pairing tools (blueman)
  # Alternative CLI tools:
  #   bluetoothctl - interactive Bluetooth control
  #   scan on, pair [address], connect [address], trust [address]
  hardware.bluetooth.enable = true;
  services.blueman.enable = true;

  #================================= Services ==========================

  services = {
    printing.enable = true; # Enable CUPS for printing
    geoclue2.enable = true; # Enable geolocation services

    udev.packages = with pkgs; [
      gnome-settings-daemon
    ];

    # Key remapping daemon - remaps capslock to control/escape
    # https://github.com/rvaiya/keyd
    keyd = {
      enable = true;
      keyboards.default.settings = {
        main = {
          # Capslock: tap = escape, hold = control
          capslock = "overload(control, esc)";
          esc = "capslock";
        };
      };
    };
  };
}
