{
  pkgs,
  values,
  ...
}:

let
  # Wrapper script for Sway with NVIDIA-specific environment variables
  swayNvidiaWrapper = pkgs.writeShellScriptBin "sway-nvidia" ''
    set -euo pipefail

    # NVIDIA Wayland support environment variables
    export LIBVA_DRIVER_NAME=nvidia
    export XDG_SESSION_TYPE=wayland
    export GBM_BACKEND=nvidia-drm
    export __GLX_VENDOR_LIBRARY_NAME=nvidia
    export __EGL_VENDOR_LIBRARY_FILENAMES=/run/opengl-driver/lib/libEGL_nvidia.so.0

    exec ${pkgs.sway}/bin/sway --unsupported-gpu "''${@}"
  '';
in
{
  # Disable greetd, use automatic login instead
  services.greetd.enable = false;

  # Configure getty for autologin
  systemd.services."getty@tty1" = {
    serviceConfig.ExecStart = [
      ""
      "${pkgs.util-linux}/sbin/agetty --autologin ${values.user.username} --noclear %I $TERM"
    ];
  };

  # Auto-start Sway on login
  environment.loginShellInit = ''
    if [[ -z $DISPLAY && $XDG_VTNR -eq 1 ]]; then
      exec ${swayNvidiaWrapper}/bin/sway-nvidia
    fi
  '';
}
