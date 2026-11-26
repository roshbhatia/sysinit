{ pkgs }:
let
  inherit (pkgs) lib;
  command = pkgs.writeShellScript "app-copy-fixture" ''
    exec ${lib.getExe pkgs.nushell} --no-config-file ${../fixtures/app-copy-command.nu} "$@"
  '';
in
pkgs.runCommand "app-copy-state-test"
  {
    nativeBuildInputs = [
      pkgs.nushell
      pkgs.coreutils
      pkgs.rsync
    ];
  }
  ''
    export APP_COPY_TEST_TOUCH=${lib.getExe' pkgs.coreutils "touch"}
    export APP_COPY_TEST_FALSE=${lib.getExe' pkgs.coreutils "false"}
    nu --no-config-file ${./app-copy-state.nu} ${../../modules/home/app-copy-state.nu} ${command}
    touch "$out"
  ''
