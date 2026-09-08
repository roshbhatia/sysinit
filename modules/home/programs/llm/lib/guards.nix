{ lib }:
let
  allowlist = import ./allowlist.nix { inherit lib; };
in
rec {
  # The destructive deny rules as the JSON file gate's bash-guard provider reads.
  rulesFile =
    pkgs: pkgs.writeText "destructive-deny-rules.json" (builtins.toJSON allowlist.destructiveDenyRules);

  # One hook entry: the gate dispatcher for a harness and an event. The chain it
  # runs comes from ~/.config/gate/config.yaml, which gate.nix renders, so a
  # harness module names the event and nothing else.
  #
  # `format` is the wire the harness reads. claude and codex read hook JSON;
  # a harness that reads only an exit status takes "exit-code", on which a
  # rewrite cannot travel and is denied instead (gate's on_rewrite_unsupported).
  # orc binds several sessions to one checkout, and a review ledger or an armed
  # loop belongs to the session that opened it. The value is relative, so gate
  # resolves it against the event's own working directory rather than wherever
  # the hook happened to run.
  gateStateDir = ''
    if [ -n "''${ORC_SESSION_ID:-}" ]; then
      export GATE_STATE_DIR=".gate/orc/''${ORC_SESSION_ID}"
    fi
  '';

  mkGateHookScript =
    {
      pkgs,
      name,
      harness,
      event,
      format ? "claude",
    }:
    pkgs.writeShellApplication {
      inherit name;
      text = ''
        ${gateStateDir}
        exec ${lib.getExe pkgs.gate-cli} hook --harness ${harness} --event ${event} --format ${format} "$@"
      '';
    };

  mkGateHook =
    {
      pkgs,
      harness,
      event,
      format ? "claude",
    }:
    lib.getExe (mkGateHookScript {
      inherit pkgs harness event format;
      name = "gate-hook-${harness}-${lib.toLower event}";
    });
}
