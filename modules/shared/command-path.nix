{ lib }:
let
  nixEntries = [
    "/run/current-system/sw/bin"
    "/nix/var/nix/profiles/default/bin"
  ];

  fallbackEntries = [
    "/usr/local/bin"
    "/usr/bin"
    "/bin"
    "/usr/sbin"
    "/sbin"
  ];

  systemEntriesFor =
    isDarwin:
    nixEntries
    ++ lib.optionals isDarwin [
      "/opt/homebrew/bin"
      "/opt/homebrew/sbin"
    ]
    ++ fallbackEntries;

  entriesFor = isDarwin: profileBin: [ profileBin ] ++ systemEntriesFor isDarwin;
in
{
  inherit entriesFor systemEntriesFor;
  renderFor = isDarwin: profileBin: lib.concatStringsSep ":" (entriesFor isDarwin profileBin);
}
