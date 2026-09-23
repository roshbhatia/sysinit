{
  lib,
  config,
  pkgs,
  osConfig,
  ...
}:

let
  # Read the declared options rather than the raw `values` specialArg. Reading
  # `values` with its own `or` defaults meant modules/darwin/options.nix never
  # typed these, so any value reached the YAML unchecked.
  cfg = osConfig.sysinit.darwin.colima;

  colimaYamlFile = (pkgs.formats.yaml { }).generate "colima.yaml" {
    inherit (cfg)
      cpu
      disk
      memory
      forwardAgent
      ;
    arch = "aarch64";
    runtime = "docker";
    hostname = "colima";
    kubernetes.enabled = false;
    autoActivate = true;
    vmType = "vz";
    mountType = "virtiofs";
    mountInotify = true;
    sshConfig = true;
    sshPort = 0;
    mounts = [ ];
    env = { };
    docker.builder.gc = {
      enabled = true;
      defaultKeepStorage = "4GB";
    };
    provision = [
      {
        mode = "system";
        script = ''
          set -eu
          mkdir -p /etc/systemd/system/fstrim.timer.d
          printf '%s\n' '[Timer]' 'OnCalendar=' 'OnCalendar=daily' \
            'RandomizedDelaySec=1h' > /etc/systemd/system/fstrim.timer.d/sysinit.conf
          systemctl daemon-reload
          systemctl enable --now fstrim.timer
          systemctl restart fstrim.timer
        '';
      }
    ];
  };
in
{
  home.sessionVariables.COLIMA_HOME = "${config.home.homeDirectory}/.colima";
  home.activation.colimaConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "$HOME/.colima/default"
    $DRY_RUN_CMD cp ${colimaYamlFile} "$HOME/.colima/default/colima.yaml"
    $DRY_RUN_CMD chmod 644 "$HOME/.colima/default/colima.yaml"
  '';
}
