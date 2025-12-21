{
  lib,
  ...
}:
{
  networking.firewall.enable = lib.mkDefault false;

  networking.networkmanager = {
    enable = true;
    dns = "systemd-resolved";
  };

  environment.enableAllTerminfo = true;

  services.avahi = {
    enable = true;
    nssmdns4 = true;
    publish = {
      enable = true;
      addresses = true;
      domain = true;
      hinfo = true;
      userServices = true;
      workstation = true;
    };
  };
}
