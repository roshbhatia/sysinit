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
in
{
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
}
