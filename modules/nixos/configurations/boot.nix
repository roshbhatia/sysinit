{ lib, ... }:

{
  # Placeholder boot configuration
  # To be customized per-host based on hardware
  boot = {
    loader = {
      efi.canTouchEfiVariables = lib.mkDefault true;
      grub = {
        enable = lib.mkDefault true;
        device = lib.mkDefault "nodev";
        efiSupport = lib.mkDefault true;
        useOSProber = lib.mkDefault true;
      };
    };
  };
}
