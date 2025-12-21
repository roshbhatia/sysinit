{
  pkgs,
  ...
}:

let
  # Wrapper script for Sway with debugging output
  swayWrapper = pkgs.writeShellScriptBin "sway-wrapped" ''
    set -euo pipefail

    # Log all output for debugging over SSH
    LOG_FILE="$HOME/.local/state/sway-debug.log"
    mkdir -p "$(dirname "$LOG_FILE")"

    {
      echo "=== Sway session started at $(date) ==="
      echo "Environment:"
      env | grep -E "(WAYLAND|XDG_SESSION|DISPLAY)" || true
      echo ""
      echo "=== Sway output ==="
    } >> "$LOG_FILE" 2>&1

    ${pkgs.sway}/bin/sway "''${@}" >> "$LOG_FILE" 2>&1 || {
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
        command = "${pkgs.tuigreet}/bin/tuigreet --time --time-format '%R' --cmd ${swayWrapper}/bin/sway-wrapped";
        user = "greeter";
      };
    };
  };
}
