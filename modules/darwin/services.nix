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
  services.tailscale.enable = lib.mkIf tailscaleEnabled true;

  services.jankyborders = lib.mkIf bordersEnabled {
    enable = true;
    width = 5.0;
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
