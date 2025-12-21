{
  pkgs,
  ...
}:

{
  programs.sway = {
    enable = true;
    package = pkgs.sway;
    xwayland.enable = true;
  };

  services.xserver.enable = false;
}
