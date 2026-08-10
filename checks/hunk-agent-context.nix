{
  pkgs,
  lib,
  ...
}:
# The export schema against what `hunk diff --agent-context` actually accepts.
let
  # The MARKED file, not a bare one: the marker rides in the root `summary`.
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

  # Rejected for the one reason the parser states: `summary` is required.
  rejected = builtins.toJSON {
    version = 1;
    files = [
      {
        path = "src/app.ts";
        annotations = [ { rationale = "no summary here"; } ];
      }
    ];
  };

  # Pinned: an input bump can turn a file watch into a poll.
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

    # A real repository: hunk resolves the diff before rendering, and a store path has
    # no working tree.
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

    # Read on stderr, not the exit code: an accepted document opens a viewer that never
    # exits on its own.
    probe() {
      timeout 30 hunk diff --agent-context "$1" --agent-notes < /dev/null > "$2" 2>&1 || true
    }

    # The literal hunk 0.18.0 message.
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
