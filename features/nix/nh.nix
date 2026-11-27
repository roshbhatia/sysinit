{
  config,
  lib,
  ...
}:
{
  programs.nh = {
    enable = true;
    clean.enable = false;
    flake = lib.mkDefault "${config.home.homeDirectory}/github/personal/roshbhatia/sysinit";
  };
}
