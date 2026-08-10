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
        # Left unset, ollama sizes context from VRAM and picks 32768, which the
        # harness prompts overrun: they measured 31k-55k tokens and came back
        # 400. 65536 clears that without the KV cost of the model's full 131072.
        OLLAMA_CONTEXT_LENGTH = "65536";

        # The runner holds the prefix cache, so unloading the model throws it
        # away. Measured on a 33222-token system prompt against
        # muse-glimmer:30b-mlx: 336.6s cold, 0.4s repeated, 5.4s with the same
        # system and a new user turn. The 5-minute default put every session
        # that resumed after a break back on the 336s path. -1 keeps the runner
        # up so the cache survives idle; the model is 22G of the 48G here, and
        # only one stays loaded at a time.
        OLLAMA_KEEP_ALIVE = "-1";
      };
    };
  };

  # The agent runs the brew binary, so a brew upgrade leaves the old server
  # running until something restarts it. Model pulls then 412 on a version
  # the client already satisfies.
  system.activationScripts.postActivation.text = ''
    launchctl kickstart -k "gui/$(id -u -- ${user})/com.ollama.default" || true
  '';
}
