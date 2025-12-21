{
  pkgs,
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
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --time-format '%R' --cmd ${swayNvidiaWrapper}/bin/sway-nvidia";
        user = "greeter";
      };
    };
  };
}
