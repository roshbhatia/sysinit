{ pkgs, ... }:

let
  startScript = pkgs.writeShellScript "ollama-start" ''
    set -euo pipefail
    /opt/homebrew/bin/ollama serve
  '';
in
{
  launchd.user.agents.ollama = {
    serviceConfig = {
      Program = toString startScript;
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "/tmp/ollama-postgres.log";
      StandardErrorPath = "/tmp/ollama-postgres.error.log";
    };
  };
}
