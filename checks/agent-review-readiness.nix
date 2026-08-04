# Moved verbatim from flake.nix. The expression is unchanged: its derivation path
# is asserted equal to the pre-move baseline in
# openspec/changes/decompose-flake-checks/drv-baseline.json.
{
  pkgs,
  lib,
  inputs,
  system,
  notifyIcons,
  managedFile,
  ...
}:
# Covers all four defects the phase fixes, not the group alone. Each
# assertion below fails if its fix is reverted; a grep for the fix's
# presence would not, because a caller can keep the call and still
# pass the wrong argument.
# `agent-review` is the gate `sy delete` consults, so its exit code is
# load-bearing: a wrong 0 discards unfinished work. Exercised against
# fixture repositories rather than by grepping the script, because every
# case here is a behaviour and none of them is visible in a pattern.
let
  notifyFor = import ../modules/home/programs/llm/runtime {
    inherit pkgs lib;
  };
in
pkgs.runCommand "agent-review-readiness-check"
  {
    nativeBuildInputs = [
      notifyFor.reviewScript
      pkgs.git
      pkgs.jq
    ];
  }
  ''
    cfg=${../modules/home/programs/llm/runtime}
    export HOME="$TMPDIR/home"
    export XDG_STATE_HOME="$TMPDIR/state"
    mkdir -p "$HOME" "$XDG_STATE_HOME"
    git config --global user.email fixture@example.invalid
    git config --global user.name Fixture
    git config --global init.defaultBranch main

    fail=0
    note() {
      echo "FAIL: $1" >&2
      printf '%s\n' "$body" | sed 's/^/    /' >&2
      fail=1
    }

    # `body` and `rc`, never `out`: $out is the derivation's output path.
    run() {
      set +e
      body="$(agent-review "$1" 2>&1)"
      rc=$?
      set -e
    }
    expect_rc() {
      [ "$rc" -eq "$2" ] || note "$1: exit $rc, expected $2"
    }
    expect_out() {
      printf '%s\n' "$body" | grep -q -- "$2" ||
        note "$1: output does not contain '$2'"
    }
    reject_out() {
      printf '%s\n' "$body" | grep -q -- "$2" &&
        note "$1: output must not contain '$2'"
      true
    }

    # A repo level with its upstream, with nothing uncommitted.
    mkrepo() {
      mkdir -p "$1"
      git init -q "$1"
      echo one > "$1/f"
      git -C "$1" add f
      git -C "$1" commit -qm one
      git init -q --bare "$1.origin.git"
      git -C "$1" remote add origin "$1.origin.git"
      git -C "$1" push -q -u origin main
    }

    # --- ready: clean and level with upstream ----------------------
    s="$TMPDIR/ready"; mkdir -p "$s"; mkrepo "$s/repo-a"
    run "$s"
    expect_rc  "ready" 0
    expect_out "ready" "clean"
    expect_out "ready" "is ready"

    # --- dirty: an uncommitted file blocks -------------------------
    s="$TMPDIR/dirty"; mkdir -p "$s"; mkrepo "$s/repo-a"
    echo two > "$s/repo-a/f"
    run "$s"
    expect_rc  "dirty" 1
    expect_out "dirty" "1 uncommitted"
    expect_out "dirty" "is not finished"

    # --- unpushed: a commit ahead of upstream blocks ---------------
    s="$TMPDIR/unpushed"; mkdir -p "$s"; mkrepo "$s/repo-a"
    echo two > "$s/repo-a/f"
    git -C "$s/repo-a" commit -qam two
    run "$s"
    expect_rc  "unpushed" 1
    expect_out "unpushed" "1 unpushed"

    # --- no upstream: said so, never reported as zero unpushed -----
    # A branch with no upstream has no answer for "how many unpushed",
    # and printing 0 would read as "nothing left to push".
    # The seshy shape: a session branch created with `worktree add -b`,
    # which sets no upstream, on a repo whose base branch IS pushed. A
    # standalone `git init` with no remote at all is not what seshy
    # creates, and asserting rc 0 on that shape hid the real defect.
    s="$TMPDIR/noupstream"; mkdir -p "$s"; mkrepo "$s/repo-a"
    git -C "$s/repo-a" checkout -q -b dev/session/repo-a
    run "$s"
    expect_out "no upstream" "(no upstream)"
    reject_out "no upstream" "0 unpushed"
    reject_out "no upstream" "commits nowhere else"
    expect_rc  "no upstream" 0

    # Same shape, but the agent committed. Those commits exist on no
    # other ref, and `sy delete` runs `branch -D`, which never refuses an
    # unmerged branch.
    s="$TMPDIR/noupstream-work"; mkdir -p "$s"; mkrepo "$s/repo-a"
    git -C "$s/repo-a" checkout -q -b dev/session/repo-a
    echo work > "$s/repo-a/f"; git -C "$s/repo-a" commit -qam work
    run "$s"
    expect_out "session branch with commits" "1 commits nowhere else"
    expect_rc  "session branch with commits" 1

    # --- liveness, driven directly, both branches --------------------
    # wezterm cannot be stubbed: agent-review is a writeShellApplication
    # whose runtimeInputs are prepended to PATH. The intersection is a
    # sourced helper for exactly that reason, so drive it with a fixed
    # live set instead of faking a mux.
    . "$cfg/agent-busy-panes.sh"
    mkdir -p "$XDG_STATE_HOME/agents/panes"
    busy_says() {
      local label="$1" want_rc="$2" session="$3" live="$4"
      set +e
      body="$(agent_busy_panes "$session" "$live")"; rc=$?
      set -e
      [ "$rc" -eq "$want_rc" ] ||
        note "$label: agent_busy_panes returned $rc, expected $want_rc"
    }

    printf '{"status":"working","agent":"claude","session":"s1"}\n' \
      > "$XDG_STATE_HOME/agents/panes/42.json"

    # A live pane holding `working` blocks, and is named.
    busy_says "live pane blocks" 1 s1 "42"
    expect_out "live pane blocks" "claude is working"

    # A state file whose pane is NOT live is ignored. This is task 1.4's
    # intersection, which had no coverage at all before.
    busy_says "dead pane ignored" 0 s1 "7"

    # A state file belonging to another session is ignored.
    busy_says "other session ignored" 0 s2 "42"

    # An idle state is not busy.
    printf '{"status":"idle","agent":"claude","session":"s1"}\n' \
      > "$XDG_STATE_HOME/agents/panes/42.json"
    busy_says "idle is not busy" 0 s1 "42"
    rm -f "$XDG_STATE_HOME/agents/panes"/*.json

    # And end to end: with no live set readable, the report skips rather
    # than blocking, because assuming liveness turns one crashed session
    # into a permanent blocker.
    s="$TMPDIR/stale"; mkdir -p "$s"; mkrepo "$s/repo-a"
    run "$s"
    expect_out "liveness unknown" "agents: skipped"
    expect_rc  "liveness unknown" 0

    # --- a clean repo after a dirty one must not clear the verdict ---
    # `unfinished` is set inside the per-repo loop and never re-checked,
    # so a reset in the clean branch would regress the whole session.
    s="$TMPDIR/mixed"; mkdir -p "$s"
    mkrepo "$s/repo-a"; mkrepo "$s/repo-b"
    echo two > "$s/repo-a/f"
    run "$s"
    expect_rc  "dirty then clean" 1
    expect_out "dirty then clean" "1 uncommitted"

    # --- an untracked file is unfinished work ------------------------
    # A file never `git add`ed exists nowhere else: no commit, no remote,
    # no reflog. A wrong "ready" here is unrecoverable.
    s="$TMPDIR/untracked"; mkdir -p "$s"; mkrepo "$s/repo-a"
    echo new > "$s/repo-a/brand-new"
    run "$s"
    expect_rc  "untracked" 1
    expect_out "untracked" "1 uncommitted"

    # --- a detached HEAD blocks, and is named ------------------------
    # `rev-parse --abbrev-ref HEAD` prints "HEAD" and exits 0 when
    # detached, so an empty-string test never fires. On a detached head
    # commits are reachable only from this worktree.
    s="$TMPDIR/detached"; mkdir -p "$s"; mkrepo "$s/repo-a"
    echo two > "$s/repo-a/f"
    git -C "$s/repo-a" commit -qam two
    git -C "$s/repo-a" checkout -q --detach HEAD
    run "$s"
    expect_out "detached" "(detached)"
    reject_out "detached" "  HEAD "
    expect_rc  "detached" 1

    # --- SESHY_SESSION names the session the state bus keys on -------
    # sy-gate passes it because the directory basename need not equal the
    # logical session name. Dropping the override makes a live agent
    # invisible.
    printf '{"status":"working","agent":"claude","session":"logical"}\n' \
      > "$XDG_STATE_HOME/agents/panes/42.json"
    busy_says "SESHY_SESSION names the bus key" 1 logical "42"
    busy_says "the directory basename would miss it" 0 ondisk "42"
    rm -f "$XDG_STATE_HOME/agents/panes"/*.json

    # --- the state reader failing must not block ----------------------
    # This gate fails OPEN by design (D3). Only a return of 1 means busy;
    # anything else is the reader itself failing, and treating that as
    # unfinished would refuse every delete with no way to tell why.
    s="$TMPDIR/readerfail"; mkdir -p "$s"; mkrepo "$s/repo-a"
    # A stub wezterm so the script reaches the reader at all. This works
    # because the assertion sources the raw script; the packaged
    # writeShellApplication prepends its own runtimeInputs and cannot be
    # stubbed, which is why the reader is a sourced helper.
    stub="$TMPDIR/stubbin"; mkdir -p "$stub"
    # A heredoc, not echo: unquoted `[{"pane_id":42}]` loses its quotes to
    # the stub shell's own expansion and jq then reads invalid JSON.
    {
      printf '#!/bin/sh\n'
      printf 'cat <<EOF\n'
      printf '[{"pane_id":42}]\n'
      printf 'EOF\n'
    } > "$stub/wezterm"
    chmod +x "$stub/wezterm"
    set +e
    body="$(PATH="$stub:$PATH" bash -c '
      agent_busy_panes() { return 42; }
      . '"$cfg"'/agent-review.sh '"$s"'
    ' 2>&1)"; rc=$?
    set -e
    expect_out "reader failure is skipped" "the state reader failed"
    expect_rc  "reader failure is skipped" 0

    # --- a paused rebase is not clean --------------------------------
    # The sequencer keeps its state in the gitdir, where
    # `status --porcelain` reports nothing. Deleting the worktree would
    # discard every commit the rebase had already applied.
    s="$TMPDIR/midrebase"; mkdir -p "$s"; mkrepo "$s/repo-a"
    echo two > "$s/repo-a/f"; git -C "$s/repo-a" commit -qam two
    echo three > "$s/repo-a/f"; git -C "$s/repo-a" commit -qam three
    GIT_SEQUENCE_EDITOR="sed -i.bak '2s/^pick/break/'" \
      git -C "$s/repo-a" rebase -i HEAD~2 > /dev/null 2>&1 || true
    run "$s"
    expect_out "paused rebase" "mid-rebase-merge"
    expect_rc  "paused rebase" 1
    git -C "$s/repo-a" rebase --abort > /dev/null 2>&1 || true

    # --- a merge paused on conflict is not clean ---------------------
    s="$TMPDIR/midmerge"; mkdir -p "$s"; mkrepo "$s/repo-a"
    git -C "$s/repo-a" checkout -q -b other
    echo other > "$s/repo-a/f"; git -C "$s/repo-a" commit -qam other
    git -C "$s/repo-a" checkout -q main
    echo main > "$s/repo-a/f"; git -C "$s/repo-a" commit -qam main
    git -C "$s/repo-a" merge other > /dev/null 2>&1 || true
    run "$s"
    expect_out "paused merge" "mid-MERGE_HEAD"
    expect_rc  "paused merge" 1

    # --- a configured upstream that no longer resolves blocks ---------
    # `fetch.prune` is set globally, so this is routine after a
    # merge-and-delete. It must NOT take the benign no-upstream carve-out:
    # the local commits may exist nowhere else.
    s="$TMPDIR/gone"; mkdir -p "$s"; mkrepo "$s/repo-a"
    echo two > "$s/repo-a/f"; git -C "$s/repo-a" commit -qam two
    git -C "$s/repo-a" update-ref -d refs/remotes/origin/main
    run "$s"
    expect_out "upstream gone" "upstream gone"
    reject_out "upstream gone" "(no upstream)"
    expect_rc  "upstream gone" 1

    # --- discovery accepts a repository root only ---------------------
    # `rev-parse --git-dir` walks upward, so without a toplevel check every
    # top-level directory of one repo reports as its own repository.
    s="$TMPDIR/nested"; mkdir -p "$s"; mkrepo "$s/repo-a"
    mkdir -p "$s/repo-a/sub-one" "$s/repo-a/sub-two"
    echo x > "$s/repo-a/sub-one/f"
    run "$s"
    [ "$(printf '%s\n' "$body" | grep -c 'sub-one\|sub-two')" -eq 0 ] ||
      note "discovery reported a subdirectory of a repo as its own repository"
    # And running FROM a repo root reports that repo once, not once per
    # top-level directory.
    # `-le 1` was satisfied by 0, so it could not tell "reported once"
    # from "never looked" — the only distinction that matters here.
    set +e
    body="$(cd "$s/repo-a" && agent-review . 2>&1)"; rc=$?
    set -e
    [ "$(printf '%s\n' "$body" | grep -c 'uncommitted')" -eq 1 ] ||
      note "running from a repo root did not report the dirty count exactly once"
    expect_rc "from a repo root" 1

    # --- an explicit argument wins over the environment --------------
    s="$TMPDIR/argwins"; mkdir -p "$s"; mkrepo "$s/repo-a"
    echo two > "$s/repo-a/f"
    set +e
    body="$(SESHY_SESSION_PATH="$TMPDIR/ready" agent-review "$s" 2>&1)"; rc=$?
    set -e
    expect_rc  "argument beats SESHY_SESSION_PATH" 1
    expect_out "argument beats SESHY_SESSION_PATH" "1 uncommitted"

    # --- a path that is not a directory skips, and says why --------
    run "$TMPDIR/absent"
    expect_rc  "absent path" 2
    expect_out "absent path" "skipping the readiness check"

    # --- commits that exist nowhere else block ------------------------
    # This is the state that actually loses work, and a missing upstream
    # does not measure it. `sy delete` runs `worktree remove --force`
    # then `branch -D`, and `branch -D` never refuses an unmerged branch,
    # so a commit reachable from no other ref is gone.
    s="$TMPDIR/localonly"; mkdir -p "$s/repo-a"
    git init -q "$s/repo-a"
    echo one > "$s/repo-a/f"; git -C "$s/repo-a" add f
    git -C "$s/repo-a" commit -qm one
    git -C "$s/repo-a" checkout -q -b feature
    echo two > "$s/repo-a/f"; git -C "$s/repo-a" commit -qam two
    run "$s"
    expect_out "commits nowhere else" "1 commits nowhere else"
    expect_rc  "commits nowhere else" 1

    # A clean session whose HEAD is reachable from another ref is still
    # ready: this must not refuse the most common delete.
    s="$TMPDIR/reachable"; mkdir -p "$s"; mkrepo "$s/repo-a"
    run "$s"
    reject_out "reachable elsewhere" "commits nowhere else"
    expect_rc  "reachable elsewhere" 0

    # --- a dot-named repo is inspected, not skipped -------------------
    # `*/` misses it, but the delete path removes it anyway: seshy
    # iterates every directory entry and runs `branch -D`.
    s="$TMPDIR/dotrepo"; mkdir -p "$s"; mkrepo "$s/.hidden"
    echo two > "$s/.hidden/f"
    run "$s"
    expect_out "dot-named repo" "1 uncommitted"
    expect_rc  "dot-named repo" 1

    # --- ambient git environment must not leak in ---------------------
    # A hook or `rebase --exec` exports these; `--show-toplevel` would
    # then answer about the ambient repo and every candidate mismatches.
    s="$TMPDIR/ambient"; mkdir -p "$s"; mkrepo "$s/repo-a"
    echo two > "$s/repo-a/f"
    set +e
    body="$(GIT_DIR="$TMPDIR/ready/repo-a/.git" \
      GIT_WORK_TREE="$TMPDIR/ready/repo-a" agent-review "$s" 2>&1)"; rc=$?
    set -e
    expect_out "ambient git env ignored" "1 uncommitted"
    expect_rc  "ambient git env ignored" 1

    # --- the shape seshy actually creates: a linked worktree ----------
    # Every other fixture is a standalone `git init`, which seshy never
    # produces. Fix 4 rests on `--git-path` resolving per-worktree markers
    # into .git/worktrees/<n>/, and fix 6 on `--show-toplevel` equalling
    # the physical path of a LINKED worktree. Neither was exercised.
    main="$TMPDIR/mainrepo"
    mkrepo "$main"
    s="$TMPDIR/wt"; mkdir -p "$s"
    git -C "$main" worktree add -q "$s/repo-a" -b dev/session/repo-a HEAD

    # Discovery must accept a linked worktree as a repository root.
    run "$s"
    expect_out "worktree is discovered" "dev/session/repo-a"
    expect_rc  "worktree is discovered" 0

    # A commit in the worktree exists on no other ref.
    echo work > "$s/repo-a/f"; git -C "$s/repo-a" commit -qam work
    run "$s"
    expect_out "worktree local commit" "1 commits nowhere else"
    expect_rc  "worktree local commit" 1

    # A paused rebase in a worktree keeps its markers under
    # .git/worktrees/<n>/, which is what `--git-path` must resolve.
    echo more > "$s/repo-a/f"; git -C "$s/repo-a" commit -qam more
    GIT_SEQUENCE_EDITOR="sed -i.bak '2s/^pick/break/'" \
      git -C "$s/repo-a" rebase -i HEAD~2 > /dev/null 2>&1 || true
    run "$s"
    expect_out "worktree paused rebase" "mid-rebase-merge"
    expect_rc  "worktree paused rebase" 1
    git -C "$s/repo-a" rebase --abort > /dev/null 2>&1 || true

    # An uncommitted change in a worktree still counts.
    echo dirty > "$s/repo-a/f"
    run "$s"
    expect_out "worktree dirty" "uncommitted"
    expect_rc  "worktree dirty" 1

    # --- examining nothing is unknown, not ready --------------------
    # Exit 2 is permissive at the gate, so nothing is trapped, but the
    # owner is told. Reporting 0 here made "found no repository" and
    # "found three clean repositories" the same answer.
    s="$TMPDIR/empty"; mkdir -p "$s/notarepo"
    run "$s"
    expect_rc  "no repositories" 2
    expect_out "no repositories" "readiness could not be determined"

    [ "$fail" -eq 0 ] || exit 1
    echo "OK: agent-review reports readiness correctly" | tee "$out"
  ''
