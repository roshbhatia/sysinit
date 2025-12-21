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

    # Log all output for debugging
    LOG_FILE="$HOME/.local/state/sway-debug.log"
    mkdir -p "$(dirname "$LOG_FILE")"

    {
      echo "=== Sway session started at $(date) ==="
      echo "Environment:"
      env | grep -E "(NVIDIA|WAYLAND|GBM|EGL|LIBVA|XDG_SESSION)" || true
      echo ""
      echo "=== Sway output ==="
    } >> "$LOG_FILE" 2>&1

    ${pkgs.sway}/bin/sway --unsupported-gpu "''${@}" >> "$LOG_FILE" 2>&1 || {
      EXIT_CODE=$?
      echo "Sway exited with code $EXIT_CODE at $(date)" >> "$LOG_FILE" 2>&1
      exit $EXIT_CODE
    }
  '';
in
{
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.tuigreet}/bin/tuigreet --time --time-format '%R' --cmd ${swayNvidiaWrapper}/bin/sway-nvidia";
        user = "greeter";
      };
    };
  };
}
