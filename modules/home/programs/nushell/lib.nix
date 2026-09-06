{ lib }:
let
  arguments = values: lib.concatMapStringsSep " " builtins.toJSON values;
in
{
  inherit arguments;
  pathAdd = paths: "path add ${arguments paths}";
  sourceProfileCompletion = profile: name: ''
    source ${builtins.toJSON "${profile}/share/nushell/vendor/autoload/${name}.nu"}
  '';
}
