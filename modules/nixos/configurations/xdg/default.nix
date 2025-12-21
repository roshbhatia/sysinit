{
  pkgs,
  ...
}:
{
  xdg.terminal-exec = {
    enable = true;
    package = pkgs.xdg-terminal-exec-mkhl;
    settings = {
      default = [ "org.wezfurlong.wezterm.desktop" ];
    };
  };

  xdg.portal = {
    enable = true;

    config = {
      common = {
        default = [ "gtk" ];
      };
    };

    xdgOpenUsePortal = true;

    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
    ];

    wlr.enable = true;
  };
}
