{ pkgs, ... }:

{
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;

    extraConfig.pipewire."99-pipewire-default.conf" = {
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
  };

  security.rtkit.enable = true;

  environment.systemPackages = with pkgs; [
    pavucontrol
    alsa-utils
    pipecontrol
  ];

  users.groups.audio = { };
}
