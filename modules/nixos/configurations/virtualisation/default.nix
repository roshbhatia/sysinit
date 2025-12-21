{
  # kvm-amd is already in hardware/default.nix
  # vfio-pci: VM passthrough not needed
  # flatpak: not needed for gaming/dev setup

  virtualisation = {
    docker.enable = false;
    # podman optional - only enable if you use containers
    podman.enable = false;
  };
}
