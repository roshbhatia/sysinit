{ pkgs }:

{
  name,
  commands,
  files ? { },
  inputs ? [ ],
  environment ? { },
}:

import ./lib.nix { inherit pkgs; } {
  inherit name inputs environment;
  script = "native-probes.nu";
  arguments = [
    (pkgs.writeText "${name}-probes.json" (builtins.toJSON { inherit commands files; }))
  ];
}
