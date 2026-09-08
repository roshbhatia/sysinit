{ lib }:
let
  allowlist = import ./allowlist.nix { inherit lib; };
in
{
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
  mkGateHook =
    {
      pkgs,
      harness,
      event,
      format ? "claude",
    }:
    "${lib.getExe pkgs.gate-cli} hook --harness ${harness} --event ${event} --format ${format}";

  # A named wrapper for a harness whose hook config wants a bare executable.
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
        exec ${lib.getExe pkgs.gate-cli} hook --harness ${harness} --event ${event} --format ${format} "$@"
      '';
    };
}
