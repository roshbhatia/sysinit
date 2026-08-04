{ lib }:
let
  allowlist = import ./allowlist.nix { inherit lib; };

  # Bash single-quote escaping: end the quote, insert an escaped quote, reopen.
  sq = s: "'" + builtins.replaceStrings [ "'" ] [ "'\\''" ] s + "'";

  # Generated so a pattern cannot live in the script but not in allowlist.nix.
  preamble = ''
    # GENERATED from llmLib.allowlist.destructiveDenyRules. Do not add a pattern
    # to this table or to the script body; add it to lib/allowlist.nix and every
    # guarded harness picks it up.
    DENY_REGEXES=(
      ${lib.concatMapStringsSep "\n      " (r: sq r.regex) allowlist.destructiveDenyRules}
    )
    DENY_REASONS=(
      ${lib.concatMapStringsSep "\n      " (r: sq r.reason) allowlist.destructiveDenyRules}
    )
  '';
  # The `destructive-guard-fixtures` check must exercise the ASSEMBLED script:
  # patterns arrive via the preamble, so the bare source file denies nothing.
  mkBashGuard =
    { pkgs, name }:
    pkgs.writeShellApplication {
      inherit name;
      runtimeInputs = [ pkgs.jq ];
      # Best-effort / fail-open: no errexit or pipefail, so a non-zero grep never
      # becomes a hook abort. Claude treats exit 2 as a block.
      bashOptions = [ ];
      text = preamble + "\n" + builtins.readFile ../runtime/bash-guard.sh;
    };
in
{
  inherit mkBashGuard;

  # For a harness that blocks by exit code rather than by a JSON
  # permissionDecision (devin's `exec`, agy's `run_command`). Both wrapped the
  # shared guard themselves and both were broken: the wrapper called it by the
  # bare name `claude-bash-guard`, which no harness puts on PATH, so the lookup
  # failed, `out` was empty, and the guard exited 0 on every command. Injecting
  # the absolute path is what makes the call resolvable, and building the pair
  # here means the two harnesses cannot drift apart again.
  mkExitCodeGuard =
    { pkgs, name }:
    let
      inner = mkBashGuard {
        inherit pkgs;
        name = "${name}-inner";
      };
    in
    pkgs.writeShellApplication {
      inherit name;
      runtimeInputs = [ pkgs.jq ];
      bashOptions = [ ];
      text = ''
        GUARD_EXE=${lib.getExe inner}
      ''
      + "\n"
      + builtins.readFile ../runtime/exit-code-guard.sh;
    };
}
