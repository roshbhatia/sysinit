{ lib }:
let
  allowlist = import ./allowlist.nix { inherit lib; };

  # Bash single-quote escaping: end the quote, insert an escaped quote, reopen.
  sq = s: "'" + builtins.replaceStrings [ "'" ] [ "'\\''" ] s + "'";

  # The pattern table the guard body loops over. Generated so a pattern cannot
  # live in the script and not in lib/allowlist.nix.
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
in
{
  # One definition for every harness that runs the script guard, and for the
  # `destructive-guard-fixtures` check. The check must exercise the assembled
  # script, not the bare source file: once the patterns arrive by preamble, the
  # bare file denies nothing and testing it would prove nothing.
  mkBashGuard =
    { pkgs, name }:
    pkgs.writeShellApplication {
      inherit name;
      runtimeInputs = [ pkgs.jq ];
      # Best-effort / fail-open: no errexit or pipefail, so a non-zero grep never
      # becomes a hook abort. Claude treats exit 2 as a block.
      bashOptions = [ ];
      text = preamble + "\n" + builtins.readFile ../config/claude-bash-guard.sh;
    };
}
