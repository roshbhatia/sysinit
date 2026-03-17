{
  pkgs,
  inputs,
  ...
}:

let
  swayfxPkg = inputs.swayfx.packages.${pkgs.system}.default;

  swayfxWrapped = pkgs.sway.override {
    sway-unwrapped = swayfxPkg;
  };
in
{
  services = {
    xserver.enable = false;
    dbus.enable = true;

    sunshine = {
      enable = true;
      openFirewall = true;
      capSysAdmin = true;
    };
  };

  programs = {
    _1password.enable = true;
    _1password-gui = {
      enable = true;
      polkitPolicyOwners = [ "rshnbhatia" ];
    };

    gamemode.enable = true;
    steam = {
      dedicatedServer = {
        openFirewall = true;
      };
      enable = true;
      remotePlay = {
        openFirewall = true;
      };
    };

    sway = {
      enable = true;
      package = swayfxWrapped;
      xwayland = {
        enable = true;
      };
      extraSessionCommands = ''
        export WLR_NO_HARDWARE_CURSORS=1
        export WLR_RENDERER=vulkan
        export GBM_BACKEND=nvidia-drm
        export __GLX_VENDOR_LIBRARY_NAME=nvidia
        export LIBVA_DRIVER_NAME=nvidia
        export XDG_SESSION_TYPE=wayland
        export NIXOS_OZONE_WL=1
        export GDK_BACKEND=wayland
        export QT_QPA_PLATFORM=wayland
        export MOZ_ENABLE_WAYLAND=1
      '';
    };
  };
}
