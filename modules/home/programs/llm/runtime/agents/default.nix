{ pkgs }:
pkgs.writeShellApplication {
  name = "agents";
  runtimeInputs = [
    pkgs.coreutils
    pkgs.openssh
  ];
  text = ''
    exec ${pkgs.nushell}/bin/nu --no-config-file ${./.}/launch.nu "$@"
  '';
}
