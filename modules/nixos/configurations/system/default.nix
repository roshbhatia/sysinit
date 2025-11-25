{ lib, ... }:
{
  # System state version - DO NOT CHANGE after initial installation
  system.stateVersion = lib.mkDefault "24.05";

  # Enable sound with PipeWire
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Enable OpenGL
  hardware.opengl = {
    enable = true;
    driSupport = true;
    driSupport32Bit = true;
  };

  # Console settings
  console = {
    font = "Lat2-Terminus16";
    keyMap = lib.mkDefault "us";
  };
}
