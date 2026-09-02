{ lib }:
let
  systemEntries = [
    "/run/current-system/sw/bin"
    "/nix/var/nix/profiles/default/bin"
    "/usr/local/bin"
    "/usr/bin"
    "/bin"
    "/usr/sbin"
    "/sbin"
  ];

  entries = profileBin: [ profileBin ] ++ systemEntries;
in
{
  inherit entries systemEntries;
  render = profileBin: lib.concatStringsSep ":" (entries profileBin);
}
