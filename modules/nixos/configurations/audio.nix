{ lib, values, ... }:

with lib;

mkMerge [
  # Only configure audio if enabled
  (mkIf values.nixos.audio.enable {
    # PipeWire configuration
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };

    # Disable PulseAudio daemon when using PipeWire
    services.pulseaudio.enable = false;
    hardware.pulseaudio.enable = false;

    # Enable real-time audio support
    security.rtkit.enable = true;
  })
]
