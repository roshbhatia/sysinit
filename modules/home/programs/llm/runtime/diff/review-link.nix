{ pkgs }:
pkgs.writeShellApplication {
  name = "agent-review-link";
  text = ''
    if [[ "''${1:-}" == --hook ]]; then
      exec ${pkgs.nushell}/bin/nu --no-config-file --stdin ${./review-link.nu} --hook
    fi
    exec ${pkgs.nushell}/bin/nu --no-config-file ${./review-link.nu} "$@"
  '';
}
