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
    "workspace-observe.ts" = ../modules/home/programs/llm/runtime/workspace/observe.ts;
    "refresh.ts" = ../modules/home/programs/llm/runtime/workspace/refresh.ts;
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
      ./agent-workspace.nu
      ../modules/home/programs/llm/runtime/workspace/workspace.nu
      ./fixtures/review-tools.nu
      ../modules/home/programs/utils/dev/ty.nu
    ]
    [
      "nu"
      "--no-config-file"
      ./diff-pane.nu
      ../modules/home/programs/llm/runtime/diff/open.nu
      ./fixtures/review-tools.nu
      ../modules/home/programs/utils/dev/ty.nu
    ]
  ];
}
