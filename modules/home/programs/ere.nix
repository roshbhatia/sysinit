{
  config,
  lib,
  pkgs,
  values,
  ...
}:
let
  connections = config.sysinit.ere.connections;
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
    name: connection:
    base
    // {
      defaultBackend = "kubernetes-pod";
      providers = lib.genAttrs [ "kubernetes-pod" "kubernetes-kubevirt" ] (
        backend:
        {
          context = name;
          inherit (connection) namespace;
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
              class = connection.storageClass;
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
              class = connection.storageClass;
              sizeGB = 30;
            };
          }
        )
      ];
    };
in
{
  options.sysinit.ere.connections = lib.mkOption {
    description = "Named private runner connections used by configuration and credential setup.";
    type = lib.types.attrsOf (
      lib.types.submodule (
        { name, ... }: {
          options = {
            sshHost = lib.mkOption {
              type = lib.types.str;
              default = name;
            };
            endpoint = lib.mkOption {
              type = lib.types.str;
              default = "https://${name}:6443";
            };
            namespace = lib.mkOption {
              type = lib.types.str;
              default = "ere";
            };
            storageClass = lib.mkOption { type = lib.types.str; };
            credentialCommand = lib.mkOption { type = lib.types.listOf lib.types.str; };
          };
        }
      )
    );
    default = {
      arrakis = {
        storageClass = "ere-retain";
        credentialCommand = [
          "sudo"
          "-n"
          "k3s"
          "kubectl"
          "config"
          "view"
          "--raw"
          "--minify"
          "-o"
          "json"
        ];
      };
      vorgossos = {
        storageClass = "zfs-path";
        credentialCommand = [
          "sudo"
          "-n"
          "/usr/local/bin/k0s"
          "kubeconfig"
          "admin"
        ];
      };
    };
  };
  config = {
    home.packages = with pkgs; [
      ere
      lima
      kubectl
      kubevirt
      openssh
      (pkgs.sysinit.writeShellApplication {
        name = "ere-setup";
        runtimeInputs = [
          pkgs.openssh
          pkgs.kubectl
        ];
        text = ''exec ${pkgs.sysinit-gotools}/bin/ere-setup --config ${config.xdg.configHome}/ere/connections.json "$@"'';
      })
    ];

    xdg.configFile =
      lib.mapAttrs' (
        target: connection:
        lib.nameValuePair "ere/${target}-boot.yaml" {
          source = (pkgs.formats.json { }).generate "ere-${target}-boot.json" {
            apiVersion = "cdi.kubevirt.io/v1beta1";
            kind = "DataVolume";
            metadata = {
              name = "${identity}-${target}-boot";
              inherit (connection) namespace;
              annotations."cdi.kubevirt.io/storage.bind.immediate.requested" = "true";
            };
            spec = {
              source.http.url = "https://cloud-images.ubuntu.com/releases/noble/release/ubuntu-24.04-server-cloudimg-amd64.img";
              storage = {
                storageClassName = connection.storageClass;
                accessModes = [ "ReadWriteOnce" ];
                resources.requests.storage = "30Gi";
              };
            };
          };
        }
      ) connections
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
        "ere/connections.json".source = (pkgs.formats.json { }).generate "ere-connections.json" connections;
      }
      // lib.mapAttrs' (
        name: connection:
        lib.nameValuePair "ere/${name}.yaml" {
          source = yaml.generate "ere-${name}.yaml" (cluster name connection);
        }
      ) connections;
  };
}
