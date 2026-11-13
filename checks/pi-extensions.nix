{ pkgs }:
pkgs.runCommand "pi-extension-tests" { nativeBuildInputs = [ pkgs.bun ]; } ''
  cp ${../modules/home/programs/llm/harnesses/pi/extensions/fm-router.ts} ./fm-router.ts
  cp ${./pi-router.test.js} ./pi-router.test.js
  bun test ./pi-router.test.js
  touch "$out"
''
