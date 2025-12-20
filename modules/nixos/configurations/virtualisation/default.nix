{
  pkgs,
  ...
}:
{
  boot.kernelModules = [
    "kvm-amd"
    "vfio-pci"
  ];
  boot.extraModprobeConfig = "options kvm_amd nested=1";

  services.flatpak.enable = true;

  virtualisation = {
    docker.enable = false;
    podman = {
      enable = true;
      dockerCompat = true;
      defaultNetwork.settings.dns_enabled = true;
      autoPrune = {
        enable = true;
        dates = "weekly";
        flags = [ "--all" ];
      };
    };

    oci-containers = {
      backend = "podman";
    };
  };

  environment.systemPackages = with pkgs; [
    qemu_kvm
    qemu
  ];
}
