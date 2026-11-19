{ pkgs }:
let
  inherit (pkgs) lib;
  renderArgument = argument: if builtins.isPath argument then "${argument}" else toString argument;
in

{
  name,
  script,
  arguments ? [ ],
  inputs ? [ ],
  environment ? { },
}:

pkgs.runCommand name
  (
    environment
    // {
      nativeBuildInputs = [
        pkgs.nushell
        pkgs.coreutils
      ]
      ++ inputs;
    }
  )
  ''
    nu --no-config-file ${./.}/${script} ${lib.escapeShellArgs (map renderArgument arguments)}
    touch "$out"
  ''
