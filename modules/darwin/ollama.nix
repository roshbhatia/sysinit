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
    };
  };

  # The agent runs the brew binary, so a brew upgrade leaves the old server
  # running until something restarts it. Model pulls then 412 on a version
  # the client already satisfies.
  system.activationScripts.postActivation.text = ''
    launchctl kickstart -k "gui/$(id -u -- ${user})/com.ollama.default" || true
  '';
}
