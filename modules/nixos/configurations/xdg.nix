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

    # Makes xdg-open use the portal to open programs
    # This resolves bugs involving programs opening inside FHS envs or with unexpected env vars set from wrappers.
    # xdg-open is used by almost all programs to open unknown files/URIs
    xdgOpenUsePortal = true;

    # Portal implementations
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk # provides file picker and OpenURI
    ];
  };
}
