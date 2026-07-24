{ pkgs, ... }:
let
  # citelock and specreview are shipped tools (used in any repo or seshy
  # session), not sysinit maintenance scripts, so they live here beside the
  # module that installs them rather than in hack/. Single source: the flake
  # check and the pre-commit hook consume the same scripts. Runtime deps (jq,
  # curl, lychee, monolith, coreutils, gawk, gnugrep) are already on PATH via
  # home.packages.
  citelock = pkgs.writeShellScriptBin "citelock" (builtins.readFile ./citelock.sh);
  specreview = pkgs.writeShellScriptBin "specreview" (builtins.readFile ./specreview.sh);
in
{
  home.packages = [
    citelock
    specreview
  ];
}
