{ pkgs }:
{
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
    printing.enable = false;
    geoclue2.enable = true;
    flatpak.enable = true;

    udev.packages = with pkgs; [
      gnome-settings-daemon
    ];

    keyd = {
      enable = false;
    };
  };

  systemd.user.services.wezterm-mux-server = {
    description = "Wezterm Mux Server";
    after = [ "default.target" ];
    wantedBy = [ "default.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.wezterm}/bin/wezterm-mux-server --daemonize";
      Restart = "always";
      RestartSec = 5;
    };
  };
}
