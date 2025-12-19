{
  pkgs,
  ...
}:

{
  programs.niri = {
    enable = true;
    package = pkgs.niri;
  };

  services.displayManager.ly.enable = true;

  services.xserver.enable = false;
}
