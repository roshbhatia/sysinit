{ pkgs, ... }:
{
  xdg.configFile."tether/config.json".source = pkgs.sysinit.writeJSON "tether-default.json" {
    mode = "auto";
    flaky = {
      rtt_ms = 60;
      loss = 0;
    };
    hosts = {
      arrakis = {
        aliases = [ "arrakis.stork-eel.ts.net." ];
        fallback = [ "arrakis.local" ];
      };
      lv426.fallback = [ "lv426.local" ];
    };
  };
}
