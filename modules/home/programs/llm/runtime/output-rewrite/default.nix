{ pkgs, lib }:
pkgs.writeShellApplication {
  name = "agent-output-rewrite";
  runtimeInputs = [
    pkgs.python3
    pkgs.vale
  ];
  text = ''
    exec python3 ${./rewrite.py} --style ${pkgs.vale-styles}/vale.ini ${lib.optionalString pkgs.stdenv.hostPlatform.isDarwin "--fm /usr/bin/fm"} "$@"
  '';
}
