{ pkgs, inputs, ... }:

let
  mangoPackage = inputs.mangowc.packages.${pkgs.system}.default;

  mangoWrapper = pkgs.writeShellScriptBin "mango-wrapped" ''
    set -euo pipefail
    # Update activation environment for dbus and systemd
    ${pkgs.dbus}/bin/dbus-update-activation-environment --systemd --all
    
    # Start the compositor
    exec ${mangoPackage}/bin/mango "''${@}"
  '';
in
{
  # Disable X server, enable dbus
  services.xserver.enable = false;
  services.dbus.enable = true;

  environment.sessionVariables = {
    WLR_NO_HARDWARE_CURSORS = "1";
    XDG_CURRENT_DESKTOP = "mango";
  };

  # Make the wrapper available system-wide
  environment.systemPackages = with pkgs; [
    mangoWrapper
    swww # Wallpaper daemon
    waybar # Status bar
    fuzzel # App launcher
    mako # Notification daemon
    nemo # File manager
    pavucontrol # Audio control
  ];
}
