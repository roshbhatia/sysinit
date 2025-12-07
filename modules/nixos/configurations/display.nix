{
  pkgs,
  ...
}:

{
  programs.niri = {
    enable = true;
  };

  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [ xdg-desktop-portal-wlr ];
  };

  services.displayManager.gdm = {
    enable = true;
    wayland = true;
  };
}
