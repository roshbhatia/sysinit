{ pkgs }:
pkgs.runCommand "pi-extension-tests" { nativeBuildInputs = [ pkgs.bun ]; } ''
  cp ${../modules/home/programs/llm/harnesses/pi/extensions/fm-router.ts} ./fm-router.ts
  cp ${./pi-router.test.js} ./pi-router.test.js
  cp ${../modules/home/programs/llm/harnesses/pi/extensions/openspec-dashboard/index.ts} ./dashboard.ts
  cp ${./pi-dashboard.test.js} ./pi-dashboard.test.js
  bun test ./pi-router.test.js ./pi-dashboard.test.js
  touch "$out"
''
