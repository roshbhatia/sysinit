{ pkgs }:
let
  inherit (pkgs) lib;
  nativeCheck = import ../lib/native.nix { inherit pkgs; };
in
nativeCheck {
  name = "codex-daemon";
  inputs = [ (pkgs.python3.withPackages (ps: [ ps.websockets ])) ];
  commands = [
    [
      "python3"
      ./codex-daemon.py
      (lib.getExe pkgs.codex)
    ]
  ];
}
