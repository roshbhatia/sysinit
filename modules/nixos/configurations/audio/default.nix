{
  ...
}:

{
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
    wireplumber.enable = true;

    extraConfig.pipewire = {
      "99-pipewire-default.conf" = {
        "context.properties" = {
          "log.level" = 2;
          "core.daemon.priority" = 80;
        };
        "context.objects" = [
          {
            factory = "metadata";
            args = "";
          }
        ];
        "stream.properties" = {
          "node.latency" = "32/48000";
          "resample.quality" = 7;
        };
      };
      # Gaming: Real-time priority for better audio performance
      pipewire = {
        "context.modules" = [
          {
            name = "libpipewire-module-rt";
            args = {
              "nice.level" = -15;
              "rt.prio" = 88;
              "rt.time.soft" = 200000;
              "rt.time.hard" = 200000;
            };
            flags = [
              "ifexists"
              "nofail"
            ];
          }
        ];
      };
    };
  };

  security.rtkit.enable = true;

  hardware.bluetooth.enable = true;
  services.blueman.enable = true;

  users.groups.audio = { };
}
