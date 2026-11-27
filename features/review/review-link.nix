{ lib, pkgs }:
let
  source = lib.fileset.toSource {
    root = ../.;
    fileset = lib.fileset.unions [
      ./review-link.nu
      ../git/review-checkpoint.nu
    ];
  };
  script = "${source}/review/review-link.nu";
in
pkgs.writeShellApplication {
  name = "agent-review-link";
  runtimeInputs = [
    pkgs.coreutils
    pkgs.git
  ];
  text = ''
    if [[ "''${1:-}" == --hook ]]; then
      exec ${pkgs.nushell}/bin/nu --no-config-file --stdin ${script} --hook
    fi
    exec ${pkgs.nushell}/bin/nu --no-config-file ${script} "$@"
  '';
}
