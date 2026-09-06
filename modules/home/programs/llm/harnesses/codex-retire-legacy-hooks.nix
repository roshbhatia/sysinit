{ lib, pkgs }:
let
  script = pkgs.writeShellScript "codex-retire-legacy-hooks" ''
    set -euo pipefail
    rm -f "$HOME/.codex/hooks.json"
  '';
in
{
  inherit script;
  activation = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD ${script}
  '';
}
