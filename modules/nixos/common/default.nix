{
  lib,
  pkgs,
  hostname,
  ...
}:

{
  networking = {
    firewall = {
      allowedUDPPorts = [ 41641 ];
      trustedInterfaces = [ "tailscale0" ];
    };
    hostName = lib.mkDefault hostname;
    networkmanager = {
      enable = true;
    };
  };

  services = {
    udisks2.enable = true;
    fwupd.enable = true;
  };

  zramSwap = {
    enable = true;
    memoryPercent = 50;
  };

  security.sudo.wheelNeedsPassword = false;

  console = {
    font = "ter-v20n";
    packages = [ pkgs.terminus_font ];
    earlySetup = true;
  };

  system.stateVersion = lib.mkDefault "25.11";

  time.timeZone = lib.mkDefault "America/Los_Angeles";
  i18n.defaultLocale = "en_US.UTF-8";
}
