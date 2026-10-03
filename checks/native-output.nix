{ pkgs }:
pkgs.runCommand "native-output-contracts"
  {
    nativeBuildInputs = [
      pkgs.bun
      pkgs.python3
    ];
  }
  ''
    cp ${../modules/home/programs/llm/harnesses/claude/output-mod/hooks/register.ts} ./claude.ts
    cp ${../modules/home/programs/llm/harnesses/opencode/plugins/sysinit-output.ts} ./opencode.ts
    cp ${./native-output.test.js} ./native-output.test.js
    bun test ./native-output.test.js
    python3 ${./output-rewrite.py} ${../modules/home/programs/llm/runtime/output-rewrite/rewrite.py}
    python3 ${./diff-pane.py} ${../modules/home/programs/llm/runtime/diff/open.py}
    touch "$out"
  ''
