{ lib, system, ... }:
let
  isDarwin = lib.hasSuffix "darwin" system;
  isLinux = lib.hasSuffix "linux" system;
  isAarch64 = lib.hasPrefix "aarch64" system;
  isX86_64 = lib.hasPrefix "x86_64" system;
in
{
  platform = {
    inherit isDarwin isLinux isAarch64 isX86_64;
    name = if isDarwin then "darwin" else "linux";
    arch = if isAarch64 then "aarch64" else "x86_64";
    
    paths = if isDarwin then {
      homebrew = "/opt/homebrew";
      systemBin = "/usr/bin:/usr/sbin";
      userProfiles = "/etc/profiles/per-user";
    } else {
      systemBin = "/usr/bin:/usr/sbin:/bin:/sbin";
      userLocal = "/usr/local/bin";
      userProfiles = "/nix/var/nix/profiles/per-user";
    };
  };
}