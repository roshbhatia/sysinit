{
  config,
  lib,
  ...
}:
{
  programs.nh = {
    enable = true;
    clean.enable = false;
    # Default; a consuming flake (e.g. sysinit.laurel) overrides this to point
    # `nh` at the flake that actually defines the host.
    flake = lib.mkDefault "${config.home.homeDirectory}/github/personal/roshbhatia/sysinit";
  };
}
