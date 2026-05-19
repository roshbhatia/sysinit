# Tasks

## 1. Author skill bodies under the change directory (reversible, contained)

- [x] 1.1 Draft `opinionated-commit` SKILL.md body at `openspec/changes/rewrite-opinionated-writing-skills/drafts/opinionated-commit.md` (follows existing pattern at `modules/home/programs/llm/skills/write-commit-roshan.nix`; no proper-noun anchor, no bolded list rows in the body itself)
- [x] 1.2 Draft `opinionated-pr` SKILL.md body at `openspec/changes/rewrite-opinionated-writing-skills/drafts/opinionated-pr.md` (follows existing pattern at `modules/home/programs/llm/skills/write-pr-body-roshan.nix`; PR template detection MUST forbid mutating the existing checklist)
- [x] 1.3 Draft `opinionated-code-comments` SKILL.md body at `openspec/changes/rewrite-opinionated-writing-skills/drafts/opinionated-code-comments.md` (new pattern; cross-references `CLAUDE.md`'s `# Doing tasks` block as the canonical source of the default-no-comments stance)
- [x] 1.4 Cross-check each draft body against the requirements in `specs/opinionated-writing-skills/spec.md` — every `MUST` and `MUST NOT` clause is verifiable against the draft
- [x] 1.5 Cross-check each draft body against the corpus at `.sysinit/laurel-corpus/` — sample at least 10 PR titles, 5 PR bodies, and 5 commit messages and confirm the draft's rules do not contradict them

## 2. Slice-1 user gate

- [x] 2.1 Verify: all three drafts complete, all spec requirements addressable, no proper-noun anchor present (grep zero matches for case-insensitive `roshan`)
- [x] 2.2 Apply: user reads the three drafts and either approves them as-is, requests edits, or scope-cuts any of the three before the nix-source slice begins
- [x] 2.3 Confirm: user has explicitly approved the three drafts before slice 2 starts

## 3. Slice-2 nix wiring (atomic switch — three new files in, three old files out, registry rewired)

- [x] 3.1 Create `modules/home/programs/llm/skills/opinionated-commit.nix` containing the approved body (follows existing per-skill `.nix`-returns-string pattern)
- [x] 3.2 Create `modules/home/programs/llm/skills/opinionated-pr.nix` containing the approved body
- [x] 3.3 Create `modules/home/programs/llm/skills/opinionated-code-comments.nix` containing the approved body
- [x] 3.4 Update `modules/home/programs/llm/skills/default.nix` — add three new entries with `description` and `content = import ./<name>.nix`, remove the three `write-*-roshan` entries
- [x] 3.5 Delete `modules/home/programs/llm/skills/write-commit-roshan.nix`, `write-pr-body-roshan.nix`, and `write-issue-roshan.nix`
- [x] 3.6 Update `CLAUDE.md`'s `## Skills` block — remove the three `write-*-roshan` bullets and add three `opinionated-*` bullets with corpus-grounded one-line descriptions
- [x] 3.7 Sweep `AGENTS.md` and any other top-level markdown for residual `write-*-roshan` references and update them to the new slugs
- [x] 3.8 Run `nix fmt` over the three new `.nix` files and `default.nix`

## 4. Slice-2 verification before applying to the system

- [x] 4.1 Verify: `nix flake check` passes
- [x] 4.2 Verify: `nh os build` completes without error and produces a buildable derivation
- [x] 4.3 Verify: review the `nh os build` profile diff — confirm the three new `~/.claude/skills/opinionated-*` paths appear and the three old `~/.claude/skills/write-*-roshan` paths are slated for removal
- [x] 4.4 Verify: stage the change as a single commit candidate (do not commit yet — `git add` only); inspect `git diff --staged` and confirm the change is one coherent slice

## 5. Apply (user-initiated impactful action)

- [ ] 5.1 Apply: USER runs `nh os switch`. NEVER auto-run by the agent.

## 6. Post-apply confirmation

- [ ] 6.1 Confirm: `ls ~/.claude/skills/opinionated-commit ~/.claude/skills/opinionated-pr ~/.claude/skills/opinionated-code-comments` all exist as symlinks
- [ ] 6.2 Confirm: `ls ~/.claude/skills/write-commit-roshan ~/.claude/skills/write-pr-body-roshan ~/.claude/skills/write-issue-roshan` all return "No such file or directory"
- [ ] 6.3 Confirm: user invokes one of the new slash commands (e.g. `/opinionated-commit`) in a new Claude Code session and verifies the skill loads and reads as expected
- [ ] 6.4 Confirm: user smoke-tests `opinionated-pr` by asking the agent to draft a PR body in a repo with a template — verify the template is filled verbatim and no checklist items are appended
- [ ] 6.5 Confirm: user smoke-tests `opinionated-code-comments` by asking the agent to add a comment to a function with an obvious name — verify the agent adds no comment

## 7. Rollback plan (only if confirmation fails)

- [ ] 7.1 Apply: `git revert` the slice-2 commit
- [ ] 7.2 Apply: USER re-runs `nh os switch` to restore the previous skill set
- [ ] 7.3 Confirm: `ls ~/.claude/skills/write-commit-roshan` etc. exists again; old skills are usable

## 8. Archive

- [ ] 8.1 Verify: all slice-2 confirm steps passed and the new skills have been in use for at least one real PR or commit drafted with them
- [ ] 8.2 Apply: USER runs `/opsx:archive rewrite-opinionated-writing-skills`. NEVER auto-run by the agent.
- [ ] 8.3 Confirm: the change folder moves to `openspec/changes/archive/` and `openspec/specs/opinionated-writing-skills/` exists with the merged requirements
