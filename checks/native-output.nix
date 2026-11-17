{ pkgs }:
pkgs.runCommand "native-output-contracts"
  {
    nativeBuildInputs = [
      pkgs.bun
      pkgs.git
      pkgs.flock
      pkgs.nushell
      pkgs.coreutils
    ];
  }
  ''
    cp ${../modules/home/programs/llm/harnesses/claude/output-mod/hooks/register.ts} ./claude.ts
    cp ${../modules/home/programs/llm/harnesses/opencode/plugins/sysinit-output.ts} ./opencode.ts
    cp ${./native-output.test.js} ./native-output.test.js
    bun test ./native-output.test.js
    nu --no-config-file ${./output-rewrite.nu} ${../modules/home/programs/llm/runtime/output-rewrite/rewrite.nu} ${./fixtures/output-rewrite-tools.nu}
    nu --no-config-file ${./diff-pane.nu} ${../modules/home/programs/llm/runtime/diff/open.nu} ${./fixtures/review-tools.nu}
    touch "$out"
  ''
