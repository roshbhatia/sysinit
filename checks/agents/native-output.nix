{ pkgs }:
let
  workspaceSource = import ../../features/workspace/source.nix { inherit (pkgs) lib; };
in
import ../lib/native.nix { inherit pkgs; } {
  name = "native-output-contracts";
  inputs = [
    pkgs.bun
    pkgs.git
    pkgs.flock
  ];
  files = {
    "claude.ts" = ../../modules/home/programs/llm/harnesses/claude/output-mod/hooks/register.ts;
    "opencode.ts" = ../../modules/home/programs/llm/harnesses/opencode/plugins/sysinit-output.ts;
    "native-output.test.js" = ./native-output.test.js;
    "agent-workspace.test.js" = ./agent-workspace.test.js;
    "workspace-codex.ts" = ../../features/workspace/codex.ts;
    "workspace-observe.ts" = ../../features/workspace/observe.ts;
    "refresh.ts" = ../../features/workspace/refresh.ts;
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
      ../../modules/home/programs/llm/runtime/output-rewrite/rewrite.nu
      ../fixtures/output-rewrite-tools.nu
    ]
    [
      "nu"
      "--no-config-file"
      ./agents.nu
      "${../../modules/home/programs/llm/runtime/agents}/launch.nu"
    ]
    [
      "nu"
      "--no-config-file"
      ./agent-workspace.nu
      "${workspaceSource}/features/workspace/workspace.nu"
      ../fixtures/review-tools.nu
      ../../features/wezterm/ty.nu
    ]
  ];
}
