{
  pkgs,
  lib,
  ...
}:
# The export schema against what `hunk diff --agent-context` actually accepts.
#
# This lives in `checks/` and not in `.githooks/pre-commit`. That hook's idiom is
# skip-when-absent, so a branch written there is a no-op on any box without hunk,
# and a guard that silently skips is the failure this check exists to catch.
# Under `checks/` the tool is present by construction, because hunk is a flake
# input, so the check cannot skip.
#
# The writer republishes the export on every note write, which makes a schema
# mismatch silent and continuous rather than loud once: the writer keeps
# producing a file hunk ignores and `review` shows empty context with no error on
# either side.
#
# Not scoped by system, and that is a finding rather than an omission. Checks are
# instantiated over `cacheSystems`, so `nativeBuildInputs = [ pkgs.hunk ]` forces
# that attribute at eval on both Linux systems too. hunk's flake provides exactly
# `aarch64-darwin`, `aarch64-linux`, and `x86_64-linux`, which is `cacheSystems`
# exactly, so there is nothing to gate. If that stops being true the eval fails,
# which is the phase's first STOP clause and is the correct place to learn it.
let
  # The accepted fixture is the MARKED file, not a bare one. The derived marker
  # rides in the root `summary`, a key hunk's parser reads, so a check against an
  # unmarked document would not cover the file the writer actually publishes.
  accepted = builtins.toJSON {
    version = 1;
    summary = "Derived from the sysinit note record. Every note write rewrites this file, so edit the record instead: sysinit-agent note path";
    files = [
      {
        path = "src/app.ts";
        annotations = [
          {
            summary = "guards an upstream bug";
            rationale = "first line of the why\nsecond line, which must survive";
            author = "pi";
            newRange = [
              2
              2
            ];
          }
        ];
      }
    ];
  };

  # Rejected for the one reason the parser states: `summary` is the only required
  # annotation field. A fixture that is merely malformed JSON would prove nothing
  # about the schema.
  rejected = builtins.toJSON {
    version = 1;
    files = [
      {
        path = "src/app.ts";
        annotations = [ { rationale = "no summary here"; } ];
      }
    ];
  };

  # Pinned because an input bump can silently turn a file watch into a poll, and
  # task 3.10's observation is the only thing that can tell the difference. It is
  # asserted against `flake.lock` and not `flake.nix`, because the input is
  # deliberately unpinned there.
  #
  # When this fails, re-run the 3.10 observation by hand, then move the string.
  expectedRev = "505d9d373aec50b7c855e536dbab477560e5168d";

  lock = builtins.fromJSON (builtins.readFile ../flake.lock);
  actualRev = lock.nodes.hunk.locked.rev;
in
assert lib.assertMsg (actualRev == expectedRev) ''
  The hunk input moved: flake.lock says ${actualRev}, this check expects ${expectedRev}.

  That is not a failure of the code. It means the watch behavior recorded in
  openspec .../make-sysinit-composable/watch-observation.md was measured against a
  different hunk. Re-run that observation by hand, then update expectedRev in
  checks/hunk-agent-context.nix.
'';
pkgs.runCommand "hunk-agent-context-check"
  {
    nativeBuildInputs = [
      pkgs.hunk
      pkgs.git
    ];
    acceptedJSON = accepted;
    rejectedJSON = rejected;
  }
  ''
    export HOME="$TMPDIR/home"
    mkdir -p "$HOME"

    # A real repository, because hunk resolves the diff before it renders it and
    # a store path has no working tree.
    repo="$TMPDIR/repo"
    mkdir -p "$repo/src"
    cd "$repo"
    git init -q .
    git config user.email check@localhost
    git config user.name check
    printf 'one\ntwo\nthree\n' > src/app.ts
    git add -A
    git -c commit.gpgsign=false commit -qm seed
    printf 'one\nTWO\nthree\n' > src/app.ts

    printf '%s\n' "$acceptedJSON" > "$TMPDIR/accepted.json"
    printf '%s\n' "$rejectedJSON" > "$TMPDIR/rejected.json"

    # Bounded, and read on stderr rather than on the exit code. A document hunk
    # accepts opens a full-screen viewer, which does not exit on its own, so the
    # exit code cannot separate "accepted" from "refused". The schema complaint
    # is printed before any of that.
    probe() {
      timeout 30 hunk diff --agent-context "$1" --agent-notes < /dev/null > "$2" 2>&1 || true
    }

    # The literal hunk 0.18.0 printed for this fixture during the 3.1 probe. A
    # looser pattern would also match a message about something else and let the
    # check pass for the wrong reason.
    refusal='Each agent annotation requires a summary'

    probe "$TMPDIR/rejected.json" "$TMPDIR/rejected.out"
    if ! grep -qF "$refusal" "$TMPDIR/rejected.out"; then
      echo "FAIL: hunk did not refuse an annotation with no summary." >&2
      echo "Either the schema loosened or this check stopped reaching the parser." >&2
      echo "--- output ---" >&2
      cat "$TMPDIR/rejected.out" >&2
      exit 1
    fi

    probe "$TMPDIR/accepted.json" "$TMPDIR/accepted.out"
    if grep -qF "$refusal" "$TMPDIR/accepted.out"; then
      echo "FAIL: hunk refused the document the note writer publishes." >&2
      echo "internal/note/export.go and this fixture have to move together." >&2
      echo "--- output ---" >&2
      cat "$TMPDIR/accepted.out" >&2
      exit 1
    fi

    echo "OK: hunk accepts the marked export and refuses a summary-less annotation" | tee "$out"
  ''
