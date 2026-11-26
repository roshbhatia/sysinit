{ pkgs }:
let
  nativeCheck = import ../lib/native.nix { inherit pkgs; };
in
nativeCheck {
  name = "tq-picker-test";
  inputs = [
    pkgs.python3
    pkgs.pueue
    pkgs.wezterm
    pkgs.bash
  ];
  commands = [
    [
      "python3"
      ./tq-picker.py
      "${pkgs.tq-picker}/bin/tq-picker"
      "${pkgs.task-queue}/bin/task-queue"
    ]
  ];
}
