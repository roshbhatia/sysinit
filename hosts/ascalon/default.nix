# Ascalon - Persistent NixOS VM (starship from The Sun Eater)
# Full NixOS system running in Lima, golden image matching macOS environment
{
  lib,
  pkgs,
  modulesPath,
  ...
}:

{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
  ];

  # Enable Lima integration (provides lima-init and lima-guestagent)
  services.lima.enable = true;

  # Nix configuration
  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    trusted-users = [ "@wheel" ];
  };

  # Hostname
  networking.hostName = "ascalon";

  # SSH
  services.openssh.enable = true;

  # Sudo without password for wheel group
  security.sudo.wheelNeedsPassword = false;

  # Boot configuration for Lima/QEMU
  boot = {
    kernelParams = [ "console=tty0" ];
    kernelPackages = pkgs.linuxPackages_latest;
    loader.grub = {
      device = "nodev";
      efiSupport = true;
      efiInstallAsRemovable = true;
    };
  };

  # Filesystems
  fileSystems."/boot" = {
    device = "/dev/vda1";
    fsType = "vfat";
  };
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    autoResize = true;
    fsType = "ext4";
    options = [
      "noatime"
      "nodiratime"
      "discard"
    ];
  };

  # System packages (minimal, most come from home-manager)
  environment.systemPackages = with pkgs; [
    vim
    git
  ];

  # Home-manager configuration for the dev user
  home-manager.users.dev = {
    imports = [
      # Ascalon gets language runtimes system-wide (same as macOS)
      ../../modules/home/packages/language-runtimes.nix
    ];

    # Packages already available via auto-imports:
    # - cli-tools.nix (all CLI utilities)
    # - dev-tools.nix (Docker, k8s, LSPs, formatters, 1Password CLI, etc.)
    # - language-managers.nix (rustup, uv, pipx)
    # Additional tools are in language-runtimes.nix imported above

    programs.home-manager.enable = true;
  };

  system.stateVersion = lib.mkForce "25.11";
}
