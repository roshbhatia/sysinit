{
  pkgs,
  ...
}:
{
  ###################################################################################
  #
  #  Virtualisation - Libvirt(QEMU/KVM) / Docker / Podman / Flatpak
  #
  ###################################################################################

  # Enable nested virtualization for AMD CPUs
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
      # Create a `docker` alias for podman, to use it as a drop-in replacement
      dockerCompat = true;
      # Required for containers under podman-compose to be able to talk to each other.
      defaultNetwork.settings.dns_enabled = true;
      # Periodically prune Podman resources
      autoPrune = {
        enable = true;
        dates = "weekly";
        flags = [ "--all" ];
      };
    };

    oci-containers = {
      backend = "podman";
    };

    # libvirtd = {
    #   enable = true;
    #   qemu.runAsRoot = true;
    # };

    # lxd.enable = true;
    # waydroid.enable = true;
  };

  environment.systemPackages = with pkgs; [
    # QEMU/KVM - HostCpuOnly, provides qemu-kvm, qemu-system-x86_64, etc.
    qemu_kvm

    # Install QEMU for other architectures
    qemu
  ];
}
