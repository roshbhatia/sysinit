{ ... }:

{
  # Boot loader configuration for UEFI systems
  boot = {
    loader = {
      # Allow NixOS to manage EFI variables (required for modern UEFI systems)
      efi.canTouchEfiVariables = true;

      # GRUB bootloader with EFI support
      grub = {
        enable = true;
        # "nodev" installs GRUB to EFI partition (standard for UEFI desktops)
        device = "nodev";
        # Enable EFI boot support
        efiSupport = true;
        # Disable OS probing - single NixOS system, no need to scan for other OSes
        useOSProber = false;
      };
    };
  };
}
