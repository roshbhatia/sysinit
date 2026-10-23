{
  lib,
  pkgs,
  home,
}:
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
  style = instructions.outputStyle;
  hasStyleOnce = text: builtins.length (lib.splitString style.rules text) == 2;
  claudeStyle = home.home.file.".claude/output-styles/${style.name}.md".text;
in
assert lib.all withoutOrc base;
assert lib.all withoutOrc styled;
assert lib.all hasStyleOnce styled;
assert lib.all (text: !(lib.hasInfix style.rules text)) base;
assert hasStyleOnce claudeStyle;
assert lib.hasInfix "keep-coding-instructions: true\n---" claudeStyle;
assert home.programs.claude-code.settings.outputStyle == style.name;
pkgs.runCommand "harness-instructions" { } "touch $out"
