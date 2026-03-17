_:

{
  services = {
    pipewire = {
      enable = true;
      alsa = {
        enable = true;
        support32Bit = true;
      };
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
        "99-realtime.conf" = {
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
    pulseaudio.enable = false;
    blueman.enable = true;
  };

  users.groups.audio = { };
}
