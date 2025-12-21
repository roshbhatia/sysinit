{
  pkgs,
  lib,
  values,
  ...
}:

let
  themes = import ../../../shared/lib/theme { inherit lib; };
  semanticColors = themes.getSemanticColors values.theme.colorscheme values.theme.variant;

  # Convert hex to color name or fallback to hex
  colorToTuigreetTheme =
    color:
    let
      # Map hex colors to common ANSI color names
      colorMap = {
        "000000" = "black";
        "ffffff" = "white";
        "ff0000" = "red";
        "00ff00" = "green";
        "0000ff" = "blue";
        "ffff00" = "yellow";
        "ff00ff" = "magenta";
        "00ffff" = "cyan";
      };
      cleanHex = lib.toLower (lib.removePrefix "#" color);
    in
    colorMap.${cleanHex} or cleanHex;

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

  # Build tuigreet theme string from semantic colors
  tuigreetTheme =
    "text=${colorToTuigreetTheme semanticColors.foreground.primary};"
    + "container=${colorToTuigreetTheme semanticColors.background.primary};"
    + "border=${colorToTuigreetTheme semanticColors.accent.primary};"
    + "title=${colorToTuigreetTheme semanticColors.accent.primary};"
    + "prompt=${colorToTuigreetTheme semanticColors.foreground.secondary};"
    + "input=${colorToTuigreetTheme semanticColors.accent.primary};"
    + "action=${colorToTuigreetTheme semanticColors.foreground.muted};"
    + "button=${colorToTuigreetTheme semanticColors.accent.secondary};"
    + "greet=${colorToTuigreetTheme semanticColors.foreground.primary}";
in
{
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.tuigreet}/bin/tuigreet --time --time-format '%R' --user-menu --remember  --theme '${tuigreetTheme}' --cmd ${swayWrapper}/bin/sway-wrapped";
        user = "greeter";
      };
    };
  };
}
