{ pkgs }:
let
  module = import ../modules/home/programs/llm/harnesses/opencode {
    inherit pkgs;
    inherit (pkgs) lib;
    config = { };
  };
  files = builtins.head module.xdg.configFile.contents;
  bridge = pkgs.writeText "opencode-bridge.zsh" files."carapace/bridge/zsh/.zshrc".text.content;
  spec = pkgs.writeText "opencode.yaml" files."carapace/specs/opencode.yaml".text;
  aliasSpec = pkgs.writeText "opencode2.yaml" files."carapace/specs/opencode2.yaml".text;
  render = import ../modules/home/programs/llm/harnesses/opencode/render.nix {
    inherit pkgs;
    inherit (pkgs) lib;
  };
  mainConfig = pkgs.writeText "opencode-main.json" (builtins.toJSON render.main);
  tuiConfig = pkgs.writeText "opencode-cli.json" (builtins.toJSON render.tui);
  fixture = pkgs.writeText "opencode-check.json" (
    builtins.toJSON {
      inherit bridge;
      inherit (render) schemas;
      main = mainConfig;
      tui = tuiConfig;
      specification = spec;
      alias = aliasSpec;
      notify = ../modules/home/programs/llm/harnesses/opencode/plugins/sysinit-notify.ts;
      process = ../modules/home/programs/llm/harnesses/opencode/plugins/sysinit-process.ts;
      edits = ../modules/home/programs/llm/harnesses/opencode/plugins/sysinit-edits.ts;
      probe = ./opencode-plugins.test.js;
    }
  );
in
import ./lib.nix { inherit pkgs; } {
  name = "opencode-v2-plugins";
  script = "opencode.nu";
  arguments = [ fixture ];
  inputs = [
    pkgs.bun
    pkgs.carapace
    pkgs.zsh
    pkgs.opencode
    pkgs.jsonschema-cli
  ];
}
