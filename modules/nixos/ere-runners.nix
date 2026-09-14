{
  config,
  lib,
  pkgs,
  hostname,
  ...
}:
let
  kubevirtOperator = pkgs.fetchurl {
    url = "https://github.com/kubevirt/kubevirt/releases/download/v1.8.4/kubevirt-operator.yaml";
    hash = "sha256-0dgmTuxbgCwSK+xsVNjDsR4RnuKlx1YCqqi1PqOFfto=";
  };
  cdiOperator = pkgs.fetchurl {
    url = "https://github.com/kubevirt/containerized-data-importer/releases/download/v1.66.1/cdi-operator.yaml";
    hash = "sha256-x9kr0bLuGjlSpZkAAEN8CNWBCfMcC9SKthiOwnoT4iQ=";
  };
  resources = (pkgs.formats.json { }).generate "ere-cluster.json" {
    apiVersion = "v1";
    kind = "List";
    items = [
      {
        apiVersion = "v1";
        kind = "Namespace";
        metadata.name = "ere";
      }
      {
        apiVersion = "storage.k8s.io/v1";
        kind = "StorageClass";
        metadata.name = "ere-retain";
        provisioner = "rancher.io/local-path";
        reclaimPolicy = "Retain";
        volumeBindingMode = "WaitForFirstConsumer";
      }
      {
        apiVersion = "kubevirt.io/v1";
        kind = "KubeVirt";
        metadata = {
          name = "kubevirt";
          namespace = "kubevirt";
        };
        spec.configuration.developerConfiguration.useEmulation = false;
      }
      {
        apiVersion = "cdi.kubevirt.io/v1beta1";
        kind = "CDI";
        metadata.name = "cdi";
        spec = { };
      }
    ];
  };
in
{
  config = lib.mkIf (hostname == "arrakis") {
    boot.kernelModules = [
      "vhost_net"
      "tun"
    ];
    boot.kernel.sysctl = {
      "fs.inotify.max_user_instances" = 8192;
      "fs.inotify.max_user_watches" = 524288;
    };
    environment.systemPackages = [ pkgs.kubevirt ];
    systemd.services.ere-cluster = {
      description = "Prepare persistent Pod and KubeVirt runners";
      wantedBy = [ "multi-user.target" ];
      wants = [ "network-online.target" ];
      requires = [ "k3s.service" ];
      after = [
        "k3s.service"
        "network-online.target"
      ];
      path = [
        pkgs.kubectl
        pkgs.coreutils
      ];
      environment.KUBECONFIG = "/etc/rancher/k3s/k3s.yaml";
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        TimeoutStartSec = "25min";
      };
      script = ''
        test -c /dev/kvm
        kubectl wait node/${hostname} --for=condition=Ready --timeout=180s
        kubectl apply --server-side -f ${kubevirtOperator}
        kubectl apply --server-side -f ${cdiOperator}
        kubectl wait crd/kubevirts.kubevirt.io crd/cdis.cdi.kubevirt.io --for=condition=Established --timeout=180s
        kubectl -n kubevirt rollout status deployment/virt-operator --timeout=180s
        kubectl -n cdi rollout status deployment/cdi-operator --timeout=180s
        kubectl apply -f ${resources}
        kubectl -n kubevirt wait kubevirt/kubevirt --for=condition=Available --timeout=600s
        kubectl wait cdi/cdi --for=condition=Available --timeout=600s
      '';
    };
    assertions = [
      {
        assertion = config.services.k3s.enable;
        message = "Arrakis runner prerequisites require K3s.";
      }
    ];
  };
}
