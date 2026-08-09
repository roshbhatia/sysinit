{
  pkgs,
  lib,
  ...
}:
# The review skill reaches every harness, asserted by destination.
#
# `hunk skill path` resolves at runtime, but the skill tree renders at build
# time, so nothing else notices when the skill stops being rendered or stops
# being installed somewhere. The design claims it reaches all eleven harnesses
# through machinery that already exists. This is that claim's only gate.
#
# Three assertions, enumerated by destination rather than by harness, because a
# skills destination in `llm/default.nix` is a closed list of four roots and the
# eleven harnesses reach them three different ways.
let
  skillName = "note";

  # `checks/` receives only `{ lib, system, pkgs }` (flake.nix:181-187), so it
  # has no handle on `self` and no evaluated home configuration to read a
  # rendered block out of. It imports the two producers directly instead.
  llmRoot = ../modules/home/programs/llm;
  skills = import (llmRoot + "/skills/render.nix") { inherit pkgs; };
  instructions = (import (llmRoot + "/lib") { inherit lib; }).instructions;

  # One: the block `makeInstructions` returns for codex.
  #
  # Only codex gets an inlined skill list. `instructions.nix:93` emits the
  # `skills` section for a harness in `harnessesWithoutSkillLoader`, and that
  # list is codex alone. Asserting the block for the other ten would fail on
  # correct code.
  #
  # `localSkillDescriptions` is a required argument of `makeInstructions` and
  # `render.nix` is its only producer, which is why this check imports it. The
  # assertion is against the RENDERED string, not against that attrset: an
  # attrset membership test proves the skill is in the description set, which is
  # a weaker claim than that it reached a harness.
  codexBlock = instructions.makeInstructions {
    harness = "codex";
    inherit (skills) localSkillDescriptions;
  };

  # `formatSkillsBlock` renders each name backticked, so the backticks are what
  # make this specific. A bare `note` is an ordinary English word and would
  # match another skill's description.
  codexToken = "`${skillName}`";

  # Two and three: where the two renders install the file.
  #
  # `renderSkillsFor "amp"` is a separate evaluation from the claude one, so it
  # can fail on its own, and an assertion on `.claude/skills/` alone stays green
  # while amp, devin, and copilot silently lose the skill.
  claudeRoot = ".claude/skills";
  ampRoots = [
    ".config/amp/skills"
    ".config/devin/skills"
    ".copilot/skills"
  ];

  # The roots live in `llm/default.nix`, which this check cannot evaluate, so it
  # reproduces the mapping and then guards the reproduction against the file
  # itself. Without the text guard, re-pointing a root there would leave this
  # check passing against roots nothing installs to.
  llmDefault = builtins.readFile (llmRoot + "/default.nix");
  destinationFor = root: ''"${root}/'' + "\${name}" + ''/SKILL.md"'';
  missingRoots = builtins.filter (root: !(lib.hasInfix (destinationFor root) llmDefault)) (
    [ claudeRoot ] ++ ampRoots
  );

  inClaudeRender = skills.allSkills ? ${skillName};
  inAmpRender = skills.ampSkills ? ${skillName};
in
assert lib.assertMsg (lib.hasInfix codexToken codexBlock) ''
  The '${skillName}' skill does not appear in the instruction block makeInstructions renders for codex.

  codex has no skill loader, so that inlined list is the only way the skill
  reaches it. Check that the skill is still in the registry under this name.
'';
assert lib.assertMsg inClaudeRender ''
  skills.allSkills has no '${skillName}' entry, so nothing installs it under ${claudeRoot}/.

  That root also serves the six harnesses with no skill copy of their own, which
  read it through skillsRoot.
'';
assert lib.assertMsg inAmpRender ''
  skills.ampSkills has no '${skillName}' entry, so amp, devin, and copilot all lose it.

  This is a separate render from the claude one and fails on its own.
'';
assert lib.assertMsg (missingRoots == [ ]) ''
  modules/home/programs/llm/default.nix no longer installs skills to: ${lib.concatStringsSep ", " missingRoots}

  This check reproduces that file's destination mapping. A root that moved there
  and not here would leave the check asserting a path nothing writes to. Update
  checks/llm-skill-destinations.nix to match.
'';
pkgs.runCommand "llm-skill-destinations-check" { } ''
  echo "OK: '${skillName}' is in the codex block, the ${claudeRoot} render, and the amp render" | tee "$out"
''
