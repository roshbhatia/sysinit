{ lib, pkgs }:
let
  instructions = import ../modules/home/programs/llm/lib/instructions.nix { inherit lib; };
  harnesses = builtins.attrNames (import ../modules/home/programs/llm/harnesses/registry.nix);
  render =
    renderer: harness:
    renderer {
      inherit harness;
      localSkillDescriptions = { };
    };
  base = map (render instructions.makeInstructions) harnesses;
  styled = map (render instructions.makeInstructionsWithStyle) harnesses;
  withoutOrc = text: !(lib.hasInfix "Orc" text) && !(lib.hasInfix "ORC_" text);
in
assert lib.all withoutOrc base;
assert lib.all withoutOrc styled;
pkgs.runCommand "harness-instructions" { } "touch $out"
