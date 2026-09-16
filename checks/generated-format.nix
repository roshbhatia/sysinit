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
pkgs.runCommand "generated-format-test"
  {
    nativeBuildInputs = [
      pkgs.shfmt
      pkgs.jq
    ];
  }
  ''
    shfmt -ln bash -i 2 -ci -sr -s -d ${script}/bin/format-fixture
    test "$(${script}/bin/format-fixture)" = "argument with spaces"
    jq --indent 2 . ${json} > expected.json
    cmp ${json} expected.json
    touch "$out"
  ''
