{ pkgs, ... }:

{
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
}
