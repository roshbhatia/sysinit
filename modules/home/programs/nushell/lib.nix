{ lib }:
let
  arguments = values: lib.concatMapStringsSep " " builtins.toJSON values;
in
{
  inherit arguments;
  pathAdd = paths: "path add ${arguments paths}";

  sourceCompletion = package: name: ''
    source ${builtins.toJSON "${package}/share/nushell/vendor/autoload/${name}.nu"}
  '';
}
