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

    # Wayland-friendly portal config
    config = {
      common = {
        default = [
          "wlr"
          "gtk"
        ];
      };
      sway = {
        default = [
          "wlr"
          "gtk"
        ];
      };
    };

    xdgOpenUsePortal = true;

    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
      xdg-desktop-portal-wlr
    ];

    wlr.enable = true;
  };
}
