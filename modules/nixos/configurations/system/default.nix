# System configuration: boot, locale, hostname, state version
{
  lib,
  hostname ? "nixos",
  ...
}:

{
  # Boot loader
  boot.loader = {
    efi.canTouchEfiVariables = true;
    timeout = lib.mkDefault 8;
    systemd-boot = {
      enable = true;
      configurationLimit = lib.mkDefault 10;
      consoleMode = lib.mkDefault "max";
    };
    grub.enable = lib.mkForce false;
  };

  # Hostname
  networking.hostName = hostname;

  # Locale
  time.timeZone = "America/Los_Angeles";
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  # State version
  system.stateVersion = "26.05";
}
