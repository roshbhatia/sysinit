{ pkgs, ... }:

{
  # Fixes "readlink: illegal option -- m" error during setupLaunchAgents
  environment.variables = {
    PATH = pkgs.lib.mkForce (
      pkgs.lib.concatStringsSep ":" [
        "/run/current-system/sw/bin"
        "/nix/var/nix/profiles/default/bin"
        "/usr/local/bin"
        "/usr/bin"
        "/bin"
        "/usr/sbin"
        "/sbin"
      ]
    );
  };

  environment.systemPackages = with pkgs; [
    coreutils
    findutils
  ];
}
