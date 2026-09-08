# The one list of hosts the session tree attaches to remotely, in the per-host
# shape tether reads. `tether` is a tether.config/v1 Host: `pin` names a tier
# that must win, and a pin never falls back silently, so a pinned tier that is
# absent on either end is an attach error rather than a downgrade. `mode`
# orders the tiers that survive (auto | native | roam | persist). An empty set
# is mode auto: the plan picks from what the probe found.
#
# arrakis stays unpinned. It runs kernel Tailscale with tailscale0 trusted, so
# inbound Mosh UDP works and mosh-mux is the target, but both ends lack mosh
# until their next switch and a pin would refuse every attach until then.
{ lib }:
let
  hosts = {
    arrakis.tether = { };
  };
in
{
  inherit hosts;
  # ~/.config/tether/config.json. The schema requires mode and flaky; the
  # thresholds are the ones tether's README documents.
  tetherConfig = {
    mode = "auto";
    flaky = {
      rtt_ms = 60;
      loss = 0;
    };
    hosts = lib.mapAttrs (_name: host: host.tether) hosts;
  };
}
