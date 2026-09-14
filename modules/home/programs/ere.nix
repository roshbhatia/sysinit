{
  config,
  lib,
  pkgs,
  values,
  ...
}:
let
  yaml = pkgs.formats.yaml { };
  identity = lib.toLower values.hostname;
  provision = [
    ''
      set -eu
      export DEBIAN_FRONTEND=noninteractive
      apt-get update
      apt-get install -y ca-certificates curl git openssh-client
      if ! test -x /opt/amp/bin/amp; then
        curl -fsSL https://ampcode.com/install.sh -o /tmp/install-amp.sh
        env HOME=/root AMP_HOME=/opt/amp bash /tmp/install-amp.sh
        rm /tmp/install-amp.sh
      fi
      chmod 755 /opt/amp /opt/amp/bin /opt/amp/bin/amp
      if ! test /usr/local/bin/amp -ef /opt/amp/bin/amp; then
        ln -s /opt/amp/bin/amp /usr/local/bin/amp
      fi
    ''
  ];
  base = {
    amp.apiKeySecret = "env://AMP_API_KEY";
    defaults = {
      cpus = 2;
      memoryMB = 4096;
      diskGB = 30;
      mountPath = "/workspace";
      inherit provision;
    };
  };
  runner = name: {
    name = "${identity}-${name}";
    runnerId = "${identity}-${name}";
    env.PATH = "/opt/amp/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin";
  };
  cluster =
    name: storageClass:
    base
    // {
      defaultBackend = "kubernetes-pod";
      providers = lib.genAttrs [ "kubernetes-pod" "kubernetes-kubevirt" ] (
        backend:
        {
          context = name;
          namespace = "ere";
          kubeconfig = "${config.home.homeDirectory}/.kube/ere-${name}.yaml";
        }
        // lib.optionalAttrs (backend == "kubernetes-kubevirt") {
          sshKey = "${config.home.homeDirectory}/.ssh/ere";
          sshUser = "ere";
        }
      );
      runners = [
        (
          (runner "${name}-pod")
          // {
            backend = "kubernetes-pod";
            image = "docker.io/library/ubuntu:24.04";
            storage = {
              kind = "pvc";
              class = storageClass;
              sizeGB = 30;
            };
          }
        )
        (
          (runner "${name}-vm")
          // {
            backend = "kubernetes-kubevirt";
            architecture = "amd64";
            bootVolume = "${identity}-${name}-boot";
            storage = {
              kind = "pvc";
              class = storageClass;
              sizeGB = 30;
            };
          }
        )
      ];
    };
in
{
  home.packages = with pkgs; [
    ere
    lima
    kubectl
    kubevirt
    openssh
    (pkgs.writeShellApplication {
      name = "ere-setup";
      runtimeInputs = [
        pkgs.openssh
        pkgs.kubectl
      ];
      text = ''exec ${pkgs.python3.withPackages (ps: [ ps.pyyaml ])}/bin/python ${./ere-setup.py} "$@"'';
    })
  ];

  xdg.configFile =
    lib.genAttrs [ "ere/arrakis-boot.yaml" "ere/vorgossos-boot.yaml" ] (
      path:
      let
        target = if lib.hasInfix "arrakis" path then "arrakis" else "vorgossos";
      in
      {
        source = (pkgs.formats.json { }).generate "ere-${target}-boot.json" {
          apiVersion = "cdi.kubevirt.io/v1beta1";
          kind = "DataVolume";
          metadata = {
            name = "${identity}-${target}-boot";
            namespace = "ere";
            annotations."cdi.kubevirt.io/storage.bind.immediate.requested" = "true";
          };
          spec = {
            source.http.url = "https://cloud-images.ubuntu.com/releases/noble/release/ubuntu-24.04-server-cloudimg-amd64.img";
            storage = {
              storageClassName = if target == "arrakis" then "ere-retain" else "zfs-path";
              accessModes = [ "ReadWriteOnce" ];
              resources.requests.storage = "30Gi";
            };
          };
        };
      }
    )
    // {
      "ere/config.yaml".source = yaml.generate "ere-local.yaml" (
        base
        // {
          defaultBackend = "lima";
          providers.lima.vmType = "auto";
          runners = [
            (
              (runner "lima")
              // {
                backend = "lima";
                image = "template://_images/ubuntu-lts";
                storage.kind = "guest-disk";
              }
            )
          ];
        }
      );
      "ere/arrakis.yaml".source = yaml.generate "ere-arrakis.yaml" (cluster "arrakis" "ere-retain");
      "ere/vorgossos.yaml".source = yaml.generate "ere-vorgossos.yaml" (cluster "vorgossos" "zfs-path");
    };
}
