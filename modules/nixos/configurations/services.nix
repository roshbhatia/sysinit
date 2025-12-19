{
  pkgs,
  ...
}:
{
  environment.systemPackages = with pkgs; [
    rustdesk
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
  };

  systemd.services.rustdesk = {
    enable = true;
    path = with pkgs; [
      rustdesk
      procps
    ];
    description = "RustDesk";
    requires = [ "network.target" ];
    after = [ "systemd-user-sessions.service" ];
    script = ''
      export PATH=/run/wrappers/bin:$PATH
      ${pkgs.rustdesk}/bin/rustdesk --service
    '';
    serviceConfig = {
      ExecStop = "${pkgs.procps}/bin/pkill -f 'rustdesk --'";
      PIDFile = "/run/rustdesk.pid";
      KillMode = "mixed";
      TimeoutStopSec = "30";
      User = "root";
      LimitNOFILE = "100000";
    };
    wantedBy = [ "multi-user.target" ];
  };
}
