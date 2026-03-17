{
  ...
}:
{
  programs.nh = {
    enable = true;
    clean.enable = false;
    flake = "${config.home.homeDirectory}/github/personal/roshbhatia/sysinit";
  };
}
