{ pkgs }:
let
  inherit (pkgs) lib;
  plugin = lib.getExe pkgs.nushellPlugins.formats;
  command = pkgs.writeShellScript "defaults-fixture" ''
    exec ${lib.getExe pkgs.nushell} --no-config-file --plugins ${plugin} ${../fixtures/defaults-command.nu} "$@"
  '';
in
pkgs.runCommand "incremental-defaults-test"
  {
    nativeBuildInputs = [ pkgs.nushell ];
    DEFAULTS_TEST_PLUGIN = plugin;
  }
  ''
    nu --no-config-file --plugins "$DEFAULTS_TEST_PLUGIN" ${./incremental-defaults.nu} ${../../modules/darwin/defaults-incremental.nu} ${command}
    touch "$out"
  ''
