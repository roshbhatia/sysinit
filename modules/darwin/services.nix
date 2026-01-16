# Darwin services: tailscale, ollama, borders
{
  lib,
  pkgs,
  values,
  ...
}:

let
  tailscaleEnabled = values.darwin.tailscale.enable or true;
  bordersEnabled = values.darwin.borders.enable;

  ollamaStartScript = pkgs.writeShellScript "ollama-start" ''
    set -euo pipefail
    /opt/homebrew/bin/ollama serve
  '';
in
{
  # Tailscale VPN
  services.tailscale.enable = lib.mkIf tailscaleEnabled true;

  # Jankyborders (window borders)
  services.jankyborders = lib.mkIf bordersEnabled {
    enable = true;
    width = 4.0;
  };

  # Ollama local LLM service
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
