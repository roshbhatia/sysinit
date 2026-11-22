{ pkgs }:
pkgs.writeShellApplication {
  name = "agents";
  text = ''
    exec ${pkgs.nushell}/bin/nu --no-config-file ${./.}/launch.nu "$@"
  '';
}
