{
  config,
  lib,
  pkgs,
  ...
}:

let
  user = lib.escapeShellArg config.system.primaryUser;

  ollamaStartScript = pkgs.writeShellScript "ollama-start" ''
    set -euo pipefail
    /opt/homebrew/bin/ollama serve
  '';
in
{
  launchd.user.agents.ollama = {
    serviceConfig = {
      Label = "com.ollama.default";
      Program = toString ollamaStartScript;
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "/tmp/ollama.log";
      StandardErrorPath = "/tmp/ollama.error.log";
      EnvironmentVariables = {
        OLLAMA_CONTEXT_LENGTH = "65536";

        OLLAMA_KEEP_ALIVE = "-1";
      };
    };
  };

  system.activationScripts.postActivation.text = ''
    launchctl kickstart -k "gui/$(id -u -- ${user})/com.ollama.default" || true
  '';
}
