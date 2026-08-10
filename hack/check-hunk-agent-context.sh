#!/usr/bin/env bash
# The export schema against what `hunk diff --agent-context` actually accepts.
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if ! command -v hunk > /dev/null 2>&1; then
  echo "check-hunk-agent-context: hunk is not on PATH, skipping" >&2
  exit 0
fi

# Pinned: an input bump can turn a file watch into a poll.
expected_rev="505d9d373aec50b7c855e536dbab477560e5168d"
actual_rev="$(jq -r '.nodes.hunk.locked.rev' "${repo_root}/flake.lock")"
if [[ ${actual_rev} != "${expected_rev}" ]]; then
  cat >&2 << EOF
check-hunk-agent-context: the hunk input moved.
flake.lock says ${actual_rev}, this check expects ${expected_rev}.

That is not a failure of the code. The watch behavior recorded in
openspec .../make-sysinit-composable/watch-observation.md was measured against a
different hunk. Re-run that observation by hand, then update expected_rev here.
EOF
  exit 1
fi

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

# The MARKED document, not a bare one: the marker rides in the root `summary`.
cat > "$work/accepted.json" << 'EOF'
{
  "version": 1,
  "summary": "Derived from the sysinit note record. Every note write rewrites this file, so edit the record instead: sysinit-agent note path",
  "files": [
    {
      "path": "src/app.ts",
      "annotations": [
        {
          "summary": "guards an upstream bug",
          "rationale": "first line of the why\nsecond line, which must survive",
          "author": "pi",
          "newRange": [2, 2]
        }
      ]
    }
  ]
}
EOF

# Rejected for the one reason the parser states: `summary` is required.
cat > "$work/rejected.json" << 'EOF'
{
  "version": 1,
  "files": [
    {
      "path": "src/app.ts",
      "annotations": [{ "rationale": "no summary here" }]
    }
  ]
}
EOF

# A real repository: hunk resolves the diff before rendering.
repo="$work/repo"
mkdir -p "$repo/src"
(
  cd "$repo"
  git init -q .
  git config user.email check@localhost
  git config user.name check
  printf 'one\ntwo\nthree\n' > src/app.ts
  git add -A
  git -c commit.gpgsign=false commit -qm seed
  printf 'one\nTWO\nthree\n' > src/app.ts
)

# Read on stderr, not the exit code: an accepted document opens a viewer that
# never exits on its own.
probe() {
  (cd "$repo" && timeout 30 hunk diff --agent-context "$1" --agent-notes < /dev/null > "$2" 2>&1 || true)
}

refusal='Each agent annotation requires a summary'

probe "$work/rejected.json" "$work/rejected.out"
if ! grep -qF "$refusal" "$work/rejected.out"; then
  echo "check-hunk-agent-context: hunk did not refuse an annotation with no summary." >&2
  echo "Either the schema loosened or this check stopped reaching the parser." >&2
  cat "$work/rejected.out" >&2
  exit 1
fi

probe "$work/accepted.json" "$work/accepted.out"
if grep -qF "$refusal" "$work/accepted.out"; then
  echo "check-hunk-agent-context: hunk refused the document the note writer publishes." >&2
  echo "internal/note/export.go and this fixture have to move together." >&2
  cat "$work/accepted.out" >&2
  exit 1
fi

echo "check-hunk-agent-context: hunk accepts the marked export and refuses a summary-less annotation"
