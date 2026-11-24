{ lib }:

script: sources:
let
  root = ../.;
  tree = lib.fileset.toSource {
    inherit root;
    fileset = lib.fileset.unions ([ script ] ++ sources);
  };
  relative = lib.removePrefix "${toString root}/" (toString script);
in
"${tree}/${relative}"
