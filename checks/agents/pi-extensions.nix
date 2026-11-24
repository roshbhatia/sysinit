{ pkgs }:
import ../lib/native.nix { inherit pkgs; } {
  name = "pi-extension-tests";
  inputs = [ pkgs.bun ];
  files = {
    "fm-router.ts" = ../../modules/home/programs/llm/harnesses/pi/extensions/fm-router.ts;
    "pi-router.test.js" = ./pi-router.test.js;
  };
  commands = [
    [
      "bun"
      "test"
      "./pi-router.test.js"
    ]
  ];
}
