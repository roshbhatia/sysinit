{ pkgs, nuFunctions }:
let
  nativeCheck = import ../lib/native.nix { inherit pkgs; };
in
nativeCheck {
  name = "pr-workflow-test";
  inputs = [
    pkgs.git
    pkgs.flock
  ];
  commands = [
    [
      "nu"
      "--no-config-file"
      "${./pr-workflow.nu}"
      "${../../features/github/gh-pr-diff.nu}"
      "${../../modules/home/programs/llm/runtime/ask-terminal.nu}"
      "${nuFunctions}"
      "${../fixtures/review-tools.nu}"
    ]
  ];
}
