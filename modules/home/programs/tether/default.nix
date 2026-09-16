{ pkgs, ... }:
{
  xdg.configFile."tether/config.json".source = pkgs.sysinit.writeJSON "tether-default.json" {
    mode = "auto";
    flaky = {
      rtt_ms = 60;
      loss = 0;
    };
    hosts = { };
  };
}
