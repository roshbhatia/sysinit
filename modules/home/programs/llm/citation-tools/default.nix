{ pkgs, ... }:
let
  # citelock is a shipped tool (used in any repo or seshy session), not a
  # sysinit maintenance script, so it lives here beside the module that
  # installs it rather than in hack/. Single source: the flake check and the
  # pre-commit hook consume the same script. Runtime deps (jq, curl, lychee,
  # monolith, coreutils) are already on PATH via home.packages.
  #
  # The rubric-lint that used to sit beside it is now `specutil check`, which
  # reads the same declared markers from specutil's own parse.
  citelock = pkgs.writeShellScriptBin "citelock" (builtins.readFile ./citelock.sh);
in
{
  home.packages = [ citelock ];
}
