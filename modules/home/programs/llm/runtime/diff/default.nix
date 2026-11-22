{ pkgs }:
pkgs.writeShellApplication {
  name = "agent-diff";
  runtimeInputs = [
    pkgs.coreutils
    pkgs.flock
    pkgs.git
    pkgs.sysinit-utils
    pkgs.wezterm
  ];
  text = ''
    exec ${pkgs.nushell}/bin/nu --no-config-file ${./.}/open.nu "$@"
  '';
}
