{ lib, ... }:

{
  boot = {
    loader = {
      efi.canTouchEfiVariables = true;
      systemd-boot = {
        enable = true;
        configurationLimit = lib.mkDefault 10;
        consoleMode = lib.mkDefault "max";
      };
      grub = {
        enable = lib.mkForce false;
      };
    };
    loader.timeout = lib.mkDefault 8;
  };
}
