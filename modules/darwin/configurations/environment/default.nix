{ pkgs, ... }:

{
  # Ensure GNU coreutils are available in PATH for system activation scripts
  # This fixes the "readlink: illegal option -- m" error during setupLaunchAgents
  environment.variables = {
    # Prioritize Nix store paths over system paths to ensure GNU tools are used
    PATH = pkgs.lib.mkForce (pkgs.lib.concatStringsSep ":" [
      "/run/current-system/sw/bin"
      "/nix/var/nix/profiles/default/bin"
      "/usr/local/bin"
      "/usr/bin"
      "/bin"
      "/usr/sbin"
      "/sbin"
    ]);
  };

  # Explicitly ensure coreutils and findutils are available system-wide
  environment.systemPackages = with pkgs; [
    coreutils  # Provides GNU readlink with -m flag support
    findutils  # Provides GNU find
  ];
}
