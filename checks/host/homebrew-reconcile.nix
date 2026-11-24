{ pkgs }:
pkgs.runCommand "homebrew-reconcile-test"
  {
    nativeBuildInputs = [
      pkgs.nushell
      pkgs.coreutils
      pkgs.bash
    ];
  }
  ''
    nu --no-config-file ${./homebrew-reconcile.nu} \
      ${../../modules/darwin/reconcile-homebrew.sh} ${../fixtures/homebrew-command.nu}
    touch "$out"
  ''
