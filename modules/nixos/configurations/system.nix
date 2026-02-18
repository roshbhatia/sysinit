# System configuration: boot, locale, hostname, nix settings, state version
{
  lib,
  values,
  ...
}:

{
  # Nix configuration
  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    trusted-users = [ "@wheel" ];
  };

  # Boot loader (defaults for non-Lima systems, Lima overrides these)
  boot.loader = {
    efi.canTouchEfiVariables = lib.mkDefault true;
    timeout = lib.mkDefault 8;
    systemd-boot = {
      enable = lib.mkDefault true;
      configurationLimit = lib.mkDefault 10;
      consoleMode = lib.mkDefault "max";
    };
    grub.enable = lib.mkDefault false;
  };

  # Hostname from values
  networking.hostName = values.hostname;

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
