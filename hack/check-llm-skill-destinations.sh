#!/usr/bin/env bash
# One skill, asserted by destination: the review skill has to reach every harness.
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
llm_root="${repo_root}/modules/home/programs/llm"
skill="note"

status=0

fail() {
  echo "check-llm-skill-destinations: $*" >&2
  status=1
}

if [[ ! -f "${llm_root}/skills/${skill}/SKILL.md" ]]; then
  fail "skills/${skill}/SKILL.md is gone, so nothing renders it to any harness."
fi

# codex has no on-demand loader, so its instruction block names every skill
# inline. Losing that flag silently drops the skill from codex.
if ! grep -q 'skillLoader = false' "${llm_root}/harnesses/registry.nix"; then
  fail "no harness is marked skillLoader = false; the inline skill list has no consumer."
fi
if ! grep -q 'harnessesWithoutSkillLoader' "${llm_root}/lib/instructions.nix"; then
  fail "lib/instructions.nix no longer inlines the skill list for loader-less harnesses."
fi

# The roots the renders install to. A root that moved in default.nix and not here
# would leave this check asserting a path nothing writes to.
for root in .claude/skills .config/amp/skills .config/devin/skills .copilot/skills; do
  if ! grep -qF "\"${root}/\${name}/SKILL.md\"" "${llm_root}/default.nix"; then
    fail "default.nix no longer installs skills to ${root}/."
  fi
done

if [[ ${status} -eq 0 ]]; then
  echo "check-llm-skill-destinations: '${skill}' reaches the inline codex list and all 4 skill roots"
fi
exit "$status"
