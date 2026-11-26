{ pkgs }:
let
  nativeCheck = import ../lib/native.nix { inherit pkgs; };
in
nativeCheck {
  name = "tq-browser-test";
  inputs = [
    (pkgs.python3.withPackages (ps: [ ps.pyte ]))
    pkgs.pueue
  ];
  commands = [
    [
      "python3"
      ./tq-browser.py
      "${pkgs.sysinit-gotools}/bin/tq"
    ]
  ];
}
