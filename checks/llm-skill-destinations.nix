{
  pkgs,
  lib,
  ...
}:
# The review skill reaches every harness, asserted by destination.
let
  skillName = "note";

  # `checks/` gets no handle on `self`, so it imports the two producers directly.
  llmRoot = ../modules/home/programs/llm;
  skills = import (llmRoot + "/skills/render.nix") { inherit pkgs; };
  instructions = (import (llmRoot + "/lib") { inherit lib; }).instructions;

  # One: the block `makeInstructions` returns for codex, the only harness in
  codexBlock = instructions.makeInstructions {
    harness = "codex";
    inherit (skills) localSkillDescriptions;
  };

  # Backticked: a bare `note` would match another skill's description.
  codexToken = "`${skillName}`";

  # Two and three: where the renders install it.
  claudeRoot = ".claude/skills";
  ampRoots = [
    ".config/amp/skills"
    ".config/devin/skills"
    ".copilot/skills"
  ];

  # This check cannot evaluate `llm/default.nix`, so it reproduces the mapping and
  # guards the reproduction against the file itself.
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
