{ lib, pkgs, values, ... }:

let
  colima = (values.darwin or { }).colima or { };
  cpu = colima.cpu or 2;
  memory = colima.memory or 4;
  disk = colima.disk or 100;
  forwardAgent = if (colima.forwardAgent or true) then "true" else "false";

  colimaYamlFile = pkgs.writeText "colima.yaml" ''
    cpu: ${toString cpu}
    disk: ${toString disk}
    memory: ${toString memory}
    arch: aarch64
    runtime: docker
    hostname: colima
    kubernetes:
      enabled: false
    autoActivate: true
    forwardAgent: ${forwardAgent}
    vmType: vz
    mountType: virtiofs
    mountInotify: true
    sshConfig: true
    sshPort: 0
    mounts: []
    env: {}
  '';
in
{
  home.activation.colimaConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "$HOME/.colima/default"
    $DRY_RUN_CMD cp ${colimaYamlFile} "$HOME/.colima/default/colima.yaml"
    $DRY_RUN_CMD chmod 644 "$HOME/.colima/default/colima.yaml"
  '';
}
