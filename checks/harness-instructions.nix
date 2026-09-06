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
  reportFragments = [
    "ORC_SESSION_ID"
    "ORC_SCOPE"
    "orc_current_session"
    "orc_session_report"
    "active Orc session"
    "`orchestrator`"
    "Set `output`"
    "`verification`"
    "`artifacts`"
    "`remaining_work`"
    "Orc Activity"
  ];
  hasOneReportInstruction =
    text:
    lib.all (fragment: lib.hasInfix fragment text) reportFragments
    && builtins.length (lib.splitString "orc_session_report" text) == 2;
in
assert lib.all hasOneReportInstruction base;
assert lib.all hasOneReportInstruction styled;
pkgs.runCommand "harness-instructions" { } ''
  touch "$out"
''
