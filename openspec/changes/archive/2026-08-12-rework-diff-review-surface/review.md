# Review decision: rework-diff-review-surface

## Rubric

- `proposal.md` `Behavior`, every WHEN/THEN pair including the four negative
  scenarios.
- `proposal.md` `Non-goals`, in particular that Neogit stays one repository.
- `design.md` `Decisions`, each with its `Alternative rejected:` lines, and the
  layer diagram that the composability claim rests on.
- `design.md` `Rollout & Gating`.
- `citations.lock`, via the `citation-verification` skill's Tier 0 gate.

An objection that cites none of these is out of scope and is discarded.

Every factual claim in `proposal.md` and `design.md` is about a file in this
repository, an installed plugin under `~/.local/share/nvim/lazy/`, or measured
output from a fixture on this machine. None is external-factual, which is why
`citations.lock` carries no records rather than being absent.

## Deterministic lint

Run 2026-08-12, per phase, before any critic.

| Check | Result |
| --- | --- |
| `specutil check` | pass, at each phase boundary |
| `stylua --check` over `config/lua/` | pass, exit 0 |
| `gofmt -l`, `go vet ./...`, `go test ./...` | pass, exit 0 |
| `nix flake check` | pass, every checked output |
| `nix build .#darwinConfigurations.lv426.system` | builds, and the `sysinit-agent` in that closure answers `workspace health` |
| headless Neovim with `:checkhealth harness` | starts with no error, report renders |

## Adversarial critique: not run, per phase

Recorded for phases 1.5, 2.4, 3.5, 4.4, and 5.4. The reason is the same in each
and is worth stating once: every defect this change actually had was a timing or
plugin-contract behaviour that reading the diff could not show.

- `:CodeDiff` is a toggle at its entry point (`codediff/commands.lua:930`), so an
  open issued from a tab that already held a session closed that session and
  opened nothing. The open loop looked correct.
- codediff registers a session against whichever tabpage is current when its
  asynchronous initialisation finishes, so four opens in one loop scrambled which
  repository landed in which tab.
- review.nvim's `_focus_modified_pane` runs 150ms after an attach and sets a
  window, which moves the current tabpage, so attaching every tab dragged the
  owner into the smallest repository.
- The inline default broke the merge editor. codediff sends a conflicted file to
  `side_by_side.update`, which rebuilds a diff pane that was closed but not an
  inline session's single one, so the owner got one side of the conflict with no
  result pane and no accept keymaps. Visible only against a repository with a real
  `UU` file.
- `git status --porcelain -z` writes a rename as `R  new\0old\0`, new path first,
  with the original in a field carrying no status prefix. The first parser read it
  the readable way round and mangled the path.

A critic reading the diff would have found none of these. Each was found by
running the code against a fixture and reading what it printed, which is the
evidence recorded under each task in `tasks.md`.

## Where a critic would still be worth it, if one is run later

Two claims rest on upstream behaviour that could change under a plugin update, so
they are the places to re-run the fixtures rather than to argue:

- that review.nvim attaches on `TabEnter`, which is what leaves the unfocused
  repositories' comment layers to it.
- that `get_layout` returns `side-by-side` for any conflicted session
  (`ui/view/init.lua:12`), which is what makes the conflict override a one-line
  decision in this repository rather than a fork.

## Rounds

None run.

## Owner decision

Decision: not-run approved
State: NOT-RUN

2026-08-12: approved. Critics NOT-RUN under the owner's direction in session ("i
approve, just approve and do the work please for all"), against a plan whose
review tasks say to run critics only when requested or risk-justified. Neither
applied. The two upstream-behaviour claims named above stay unexamined by a
critic and are covered by fixtures instead.
