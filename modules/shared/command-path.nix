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

  # NixOS puts setuid binaries (sudo) in /run/wrappers/bin; the same names in
  # the system profile are the unwrapped store copies and refuse to run.
  systemEntriesFor =
    isDarwin:
    lib.optionals (!isDarwin) [ "/run/wrappers/bin" ]
    ++ nixEntries
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
