{ pkgs, ... }:
let
  # Expose citelock and specreview as PATH commands so any repo or seshy session
  # can call them without vendoring the scripts. Single source: the bins are
  # generated from the in-repo hack/ scripts, which the flake check and the
  # pre-commit hook also use directly. Runtime deps (jq, curl, lychee, monolith,
  # coreutils, gawk, gnugrep) are already installed via home.packages, so the
  # scripts resolve them from PATH.
  citelock = pkgs.writeShellScriptBin "citelock" (builtins.readFile ../../../../hack/citelock.sh);
  specreview = pkgs.writeShellScriptBin "specreview" (builtins.readFile ../../../../hack/specreview.sh);
in
{
  home.packages = [
    citelock
    specreview
  ];
}
