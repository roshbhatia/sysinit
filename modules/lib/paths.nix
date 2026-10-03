{ lib, ... }:
let
  commandPath = import ../shared/command-path.nix { inherit lib; };
  getAllPaths =
    username: home:
    commandPath.homeEntriesFor (lib.hasPrefix "/Users/" home) "/etc/profiles/per-user/${username}/bin"
      home;
in
{
  inherit getAllPaths;
  getPathString = username: home: lib.concatStringsSep ":" (getAllPaths username home);
}
