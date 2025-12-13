{
  pkgs,
  ...
}:

{
  programs.niri = {
    enable = true;
    package = pkgs.niri;
  };

  services.displayManager.gdm = {
    enable = true;
    wayland = true;
  };
}
