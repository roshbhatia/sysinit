{ lib }:
let
  arguments = values: lib.concatMapStringsSep " " builtins.toJSON values;
in
{
  inherit arguments;
  pathAdd = paths: "path add ${arguments paths}";
  # The file is read from the package's own store path. The per-user profile
  # links only environment.pathsToLink, and NixOS does not list /share/nushell,
  # so a profile path resolved on Darwin and failed the parser on arrakis.
  sourceCompletion = package: name: ''
    source ${builtins.toJSON "${package}/share/nushell/vendor/autoload/${name}.nu"}
  '';
}
