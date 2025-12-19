{
  pkgs,
  ...
}:

{
  programs.niri = {
    enable = true;
    package = pkgs.niri;
  };

  services.displayManager.ly = {
    enable = true;
    recommendedSession = "niri";
  };

  services.xserver.enable = false;
}
