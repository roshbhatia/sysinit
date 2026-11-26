{ pkgs }:
let
  inherit (pkgs) lib;
  renderArgument = argument: if builtins.isPath argument then "${argument}" else toString argument;
  probeSource = import ./probe-source.nix { inherit lib; };
in

{
  name,
  script,
  sources ? [ ],
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
    nu --no-config-file ${probeSource script sources} ${lib.escapeShellArgs (map renderArgument arguments)}
    touch "$out"
  ''
