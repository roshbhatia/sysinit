{ pkgs }:
import ./native.nix { inherit pkgs; } {
  name = "native-output-contracts";
  inputs = [
    pkgs.bun
    pkgs.git
    pkgs.flock
  ];
  files = {
    "claude.ts" = ../modules/home/programs/llm/harnesses/claude/output-mod/hooks/register.ts;
    "opencode.ts" = ../modules/home/programs/llm/harnesses/opencode/plugins/sysinit-output.ts;
    "native-output.test.js" = ./native-output.test.js;
    "agent-workspace.test.js" = ./agent-workspace.test.js;
    "workspace-codex.ts" = ../modules/home/programs/llm/runtime/workspace/codex.ts;
  };
  commands = [
    [
      "bun"
      "test"
      "./native-output.test.js"
      "./agent-workspace.test.js"
    ]
    [
      "nu"
      "--no-config-file"
      ./output-rewrite.nu
      ../modules/home/programs/llm/runtime/output-rewrite/rewrite.nu
      ./fixtures/output-rewrite-tools.nu
    ]
    [
      "nu"
      "--no-config-file"
      ./diff-pane.nu
      ../modules/home/programs/llm/runtime/diff/open.nu
      ./fixtures/review-tools.nu
    ]
  ];
}
