# Darwin services: tailscale, ollama, borders
{
  lib,
  pkgs,
  values,
  config,
  ...
}:

let
  tailscaleEnabled = values.darwin.tailscale.enable or true;
  bordersEnabled = values.darwin.borders.enable;

  # Access stylix colors for jankyborders
  colors = config.lib.stylix.colors;

  # Convert hex to jankyborders format (0xAARRGGBB)
  # Using full opacity (ff) for borders
  hexToJanky = hex: "0xff${hex}";

  ollamaStartScript = pkgs.writeShellScript "ollama-start" ''
    set -euo pipefail
    /opt/homebrew/bin/ollama serve
  '';
in
{
  services.tailscale.enable = lib.mkIf tailscaleEnabled true;

  services.jankyborders = lib.mkIf bordersEnabled {
    enable = true;
    width = 6.0;
    active_color = lib.mkForce (hexToJanky colors.base0D); # Accent blue for active window
    inactive_color = lib.mkForce (hexToJanky colors.base02); # Subtle gray for inactive windows
  };

  launchd.user.agents.ollama = {
    serviceConfig = {
      Label = "com.ollama.default";
      Program = toString ollamaStartScript;
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "/tmp/ollama-postgres.log";
      StandardErrorPath = "/tmp/ollama-postgres.error.log";
    };
  };
}
