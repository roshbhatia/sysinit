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
        AMP_HOME=/opt/amp bash /tmp/install-amp.sh
        rm /tmp/install-amp.sh
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
          namespace = "lifier";
          kubeconfig = "${config.home.homeDirectory}/.kube/lifier-${name}.yaml";
        }
        // lib.optionalAttrs (backend == "kubernetes-kubevirt") {
          sshKey = "${config.home.homeDirectory}/.ssh/lifier";
          sshUser = "lifier";
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
    lifier
    lima
    kubectl
    kubevirt
    openssh
    (pkgs.writeShellApplication {
      name = "lifier-setup";
      runtimeInputs = [
        pkgs.openssh
        pkgs.kubectl
      ];
      text = ''exec ${
        pkgs.python3.withPackages (ps: [ ps.pyyaml ])
      }/bin/python ${./lifier-setup.py} "$@"'';
    })
  ];

  xdg.configFile =
    lib.genAttrs [ "lifier/arrakis-boot.yaml" "lifier/vorgossos-boot.yaml" ] (
      path:
      let
        target = if lib.hasInfix "arrakis" path then "arrakis" else "vorgossos";
      in
      {
        source = yaml.generate "lifier-${target}-boot.yaml" {
          apiVersion = "cdi.kubevirt.io/v1beta1";
          kind = "DataVolume";
          metadata = {
            name = "${identity}-${target}-boot";
            namespace = "lifier";
            annotations."cdi.kubevirt.io/storage.bind.immediate.requested" = "true";
          };
          spec = {
            source.http.url = "https://cloud-images.ubuntu.com/releases/noble/release/ubuntu-24.04-server-cloudimg-amd64.img";
            storage = {
              storageClassName = if target == "arrakis" then "lifier-retain" else "zfs-path";
              accessModes = [ "ReadWriteOnce" ];
              resources.requests.storage = "30Gi";
            };
          };
        };
      }
    )
    // {
      "lifier/config.yaml".source = yaml.generate "lifier-local.yaml" (
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
      "lifier/arrakis.yaml".source = yaml.generate "lifier-arrakis.yaml" (
        cluster "arrakis" "lifier-retain"
      );
      "lifier/vorgossos.yaml".source = yaml.generate "lifier-vorgossos.yaml" (
        cluster "vorgossos" "zfs-path"
      );
    };
}
