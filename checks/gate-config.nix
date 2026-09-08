# The default gate chains validate against the providers that ship, with the
# same renderer the module uses. A chain that names a provider with no manifest
# is a hook that exits 1 on every call, which is worse than no hook.
{ pkgs, lib }:
let
  llmLib = import ../modules/home/programs/llm/lib { inherit lib; };
  defaults = import ../modules/home/programs/llm/gate-defaults.nix {
    rulesFile = "${llmLib.guards.rulesFile pkgs}";
  };
  yamlFormat = pkgs.formats.yaml { };
  renderStep =
    step:
    {
      inherit (step) provider;
    }
    // lib.optionalAttrs (step ? match) { inherit (step) match; }
    // lib.optionalAttrs (step ? args) { inherit (step) args; };
  configFile = yamlFormat.generate "gate-config.yaml" {
    version = "gate.config/v1";
    log = "/tmp/gate-decisions.jsonl";
    providers.directory = "@providers@";
    defaults = {
      timeout = "2s";
      on_rewrite_unsupported = "deny";
    };
    chains = lib.mapAttrs (_event: steps: map renderStep steps) defaults.chains;
  };
  reviewFile = yamlFormat.generate "gate-review.yaml" defaults.review;
  proseGate = yamlFormat.generate "prose-gate.yaml" {
    version = "provider/v1";
    name = "prose-gate";
    description = "sysinit's prose gate";
    command = [ "${pkgs.sysinit-utils}/bin/prose-gate" ];
    actions."gate.decide" = {
      description = "check";
      argv = [ "serve" ];
    };
    defaults.timeout = "5s";
  };
  gitAiGate = yamlFormat.generate "git-ai-gate.yaml" {
    version = "provider/v1";
    name = "git-ai-gate";
    description = "sysinit's git-ai checkpoint gate";
    command = [ "${pkgs.git-ai-gate}/bin/git-ai-gate" ];
    actions."gate.decide" = {
      description = "checkpoint";
      argv = [ "serve" ];
    };
    defaults.timeout = "10s";
  };
in
pkgs.runCommand "gate-config"
  {
    nativeBuildInputs = [
      pkgs.gate-cli
      pkgs.gate-providers
      pkgs.sysinit-utils
      pkgs.git-ai-gate
    ];
  }
  ''
    export HOME="$TMPDIR/home"
    export XDG_CONFIG_HOME="$TMPDIR/config"
    export XDG_STATE_HOME="$TMPDIR/state"
    mkdir -p "$HOME" "$XDG_CONFIG_HOME/gate/providers" "$XDG_STATE_HOME"
    cp ${pkgs.gate-providers}/share/gate/providers/*.yaml "$XDG_CONFIG_HOME/gate/providers/"
    cp ${proseGate} "$XDG_CONFIG_HOME/gate/providers/prose-gate.yaml"
    cp ${gitAiGate} "$XDG_CONFIG_HOME/gate/providers/git-ai-gate.yaml"
    sed "s|@providers@|$XDG_CONFIG_HOME/gate/providers|" ${configFile} > "$XDG_CONFIG_HOME/gate/config.yaml"
    cp ${reviewFile} "$XDG_CONFIG_HOME/gate/review.yaml"
    gate config validate
    GATE_REVIEW_CONFIG="$XDG_CONFIG_HOME/gate/review.yaml" review policy > /dev/null
    # A destructive command is denied through the whole chain, not only in a
    # unit test of the provider.
    printf '%s' '{"hook_event_name":"PreToolUse","tool_name":"Bash","tool_input":{"command":"git push --force"},"cwd":"/"}' \
      | gate hook --harness claude --event PreToolUse --format json > decision
    grep -q '"decision":"deny"' decision
    touch "$out"
  ''
