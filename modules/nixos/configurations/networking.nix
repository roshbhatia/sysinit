{
  lib,
  ...
}:
{
  networking.firewall.enable = lib.mkDefault false;

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
