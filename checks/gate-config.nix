# The default gate chains validate against the providers that ship, with the
# same renderer the module uses. A chain that names a provider with no manifest
# is a hook that exits 1 on every call, which is worse than no hook.
{ pkgs, lib }:
let
  llmLib = import ../modules/home/programs/llm/lib { inherit lib; };
  defaults = import ../modules/home/programs/llm/gate-defaults.nix {
    rulesFile = "${llmLib.guards.rulesFile pkgs}";
    styleFile = "${pkgs.vale-styles}/vale.ini";
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
    # The sandbox cannot write /tmp, and gate drops a provider's stderr into
    # this log, so an unwritable path hides why a decision went wrong.
    log = "@log@";
    providers.directory = "@providers@";
    defaults = {
      timeout = "2s";
      on_rewrite_unsupported = "deny";
    };
    chains = lib.mapAttrs (_event: steps: map renderStep steps) defaults.chains;
  };
  reviewFile = yamlFormat.generate "gate-review.yaml" defaults.review;
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
      pkgs.git-ai-gate
    ];
  }
  ''
    export HOME="$TMPDIR/home"
    export XDG_CONFIG_HOME="$TMPDIR/config"
    export XDG_STATE_HOME="$TMPDIR/state"
    mkdir -p "$HOME" "$XDG_CONFIG_HOME/gate/providers" "$XDG_STATE_HOME"
    cp ${pkgs.gate-providers}/share/gate/providers/*.yaml "$XDG_CONFIG_HOME/gate/providers/"
    cp ${gitAiGate} "$XDG_CONFIG_HOME/gate/providers/git-ai-gate.yaml"
    sed -e "s|@providers@|$XDG_CONFIG_HOME/gate/providers|" -e "s|@log@|$TMPDIR/gate-decisions.jsonl|" \
      ${configFile} > "$XDG_CONFIG_HOME/gate/config.yaml"
    cp ${reviewFile} "$XDG_CONFIG_HOME/gate/review.yaml"
    gate config validate
    GATE_REVIEW_CONFIG="$XDG_CONFIG_HOME/gate/review.yaml" review policy > /dev/null
    # A destructive command is denied through the whole chain, not only in a
    # unit test of the provider.
    printf '%s' '{"hook_event_name":"PreToolUse","tool_name":"Bash","tool_input":{"command":"git push --force"},"cwd":"/"}' \
      | gate hook --harness claude --event PreToolUse --format json > decision
    grep -q '"decision":"deny"' decision
    # An open note the owner left reaches the model on the next prompt through
    # the whole UserPromptSubmit chain, as context rather than as a raw hook.
    printf 'one\n' > annotated.txt
    note add --file annotated.txt --line 1 --summary 'why is this here' --origin user
    printf '%s' '{"hook_event_name":"UserPromptSubmit","prompt":"hi","cwd":"/"}' \
      | gate hook --harness claude --event UserPromptSubmit --format json > prompt
    grep -q '"decision":"context"' prompt
    grep -q 'why is this here' prompt
    # prose-gate's rules are arguments, so the chain is what proves them: a
    # reply in agent prose is recorded on Stop, silently, and the next prompt
    # carries the findings with this repository's reminder.
    export PROSE_GATE_STATE_DIR="$TMPDIR/prose"
    printf '%s' '{"hook_event_name":"Stop","session_id":"s1","stop_hook_active":false,"last_assistant_message":"Basically, this seamlessly leverages a pivotal unlock. In summary, we delivered a robust solution."}' \
      | gate hook --harness claude --event Stop --format json > stop
    test ! -s stop
    printf '%s' '{"hook_event_name":"UserPromptSubmit","session_id":"s1","prompt":"go"}' \
      | gate hook --harness claude --event UserPromptSubmit --format json > prompt
    if ! grep -q 'read like agent prose' prompt || ! grep -q 'sysinit-ste output style is active' prompt; then
      echo "prose-gate did not carry the findings into the prompt:" >&2
      cat prompt "$TMPDIR/gate-decisions.jsonl" >&2
      exit 1
    fi
    touch "$out"
  ''
