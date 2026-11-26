{ pkgs }:
let
  script = pkgs.sysinit.writeShellApplication {
    name = "format-fixture";
    text = ''
      if true;then
      printf '%s\n' "argument with spaces"
      fi
    '';
  };
  json = pkgs.sysinit.writeJSON "format-fixture.json" {
    values = [
      "a b"
      "c"
    ];
  };
in
import ../lib/nushell.nix { inherit pkgs; } {
  name = "generated-format-test";
  script = ./generated-format.nu;
  sources = [ ../lib/process.nu ];
  arguments = [
    "${script}/bin/format-fixture"
    json
  ];
  inputs = [
    pkgs.shfmt
    pkgs.jq
  ];
}
