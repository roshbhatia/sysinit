{ lib, pkgs }:
let
  source = lib.fileset.toSource {
    root = ../.;
    fileset = lib.fileset.unions [
      ./.
      ../wezterm/mux.nu
    ];
  };
in
pkgs.writeShellApplication {
  name = "agent-diff";
  runtimeInputs = [
    pkgs.coreutils
    pkgs.flock
    pkgs.git
    pkgs.sysinit-ty
    pkgs.wezterm
  ];
  text = ''
    exec ${pkgs.nushell}/bin/nu --no-config-file ${source}/review/open.nu "$@"
  '';
}
