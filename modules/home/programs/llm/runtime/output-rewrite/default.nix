{ pkgs, lib }:
pkgs.writeShellApplication {
  name = "agent-output-rewrite";
  runtimeInputs = [
    pkgs.coreutils
    pkgs.vale
  ];
  text = ''
    exec ${lib.getExe pkgs.nushell} --no-config-file --stdin ${./rewrite.nu} --style ${pkgs.vale-styles}/vale.ini ${lib.optionalString pkgs.stdenv.hostPlatform.isDarwin "--fm /usr/bin/fm"} "$@"
  '';
}
