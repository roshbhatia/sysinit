> The keywords MUST, MUST NOT, SHOULD, SHOULD NOT, and MAY in this document are
> to be interpreted as described in [RFC 2119](https://datatracker.ietf.org/doc/html/rfc2119).

## Why

`tasks.md` declares a dependency graph, and five of the rules that would make
the graph honest are absent. Each defect below is stated as what the current
artifacts do, with the file that does it.

The tasks instruction tells the author to "Order tasks by dependency (what must
be done first?)", at `modules/home/programs/llm/openspec-schema/schema.yaml`.
Sequencing and data flow are different questions, and that sentence asks the
first one. An edge drawn because a task feels later does not describe a result
the next task reads, so a `graph` phase serializes work that could run at once.
Nothing in the rubric distinguishes the two kinds of edge, so nothing catches
it. This change's own `tasks.md` carried such an edge until the review found it.

The apply instruction permits fan-out when "parallel work materially helps", in
the same file. That is a judgement with no negative case, so it never says do
not fan out. It cannot be repaired by keying the prohibition on whether the
subtasks read each other's output: `specutil next` releases a subtask only when
every declared dependency is complete, so a ready set never contains two tasks
with an edge between them, and a prohibition scoped that way has an empty
extension. The coupling that survives into a ready set is not the declared edge.
It is the shared file. Two subtasks with no edge between them routinely write
the same registry, and fanning those out produces a merge conflict rather than
parallel progress.

No artifact names who owns the merge when a `graph` phase fans out, so the merge
is read out of file order, which is the thing the declared graph exists to stop
being load-bearing.

The apply instruction already tells a fan-out to "Give each a disjoint file set
and say so in the prompt", in the same file. Nothing in `tasks.md` declares that
set, so the instruction asks the orchestrator to invent one per fan-out from the
task prose, and nothing can decide whether two subtasks in one ready set collide.

The extractor lifts a marker by the first match on the task line, and strips a
leading kind verb from the task text. Neither behaviour is stated anywhere an
author reads. Both misfire in practice: a task whose prose repeats a marker
label silently takes the prose as the marker value and truncates the rendered
text at that point, and a task that opens with `Apply` loses that word from
every projection. Both were observed in this change's own `tasks.md` before it
was corrected.

The evidence below is about agent architecture, not about this repository. The
inference from it is the author's, and is recorded as such. A controlled study
of agent systems reports that relative performance against a single-agent
baseline "ranges from +80.8% on decomposable financial reasoning to -70.0% on
sequential planning" [cite: scaling-agents-task-structure], and that agent
"effectiveness depends on alignment between coordination and task structure, and
that mismatched coordination degrades the performance"
[cite: scaling-agents-mismatch]. That range runs in both directions, and its
positive magnitude is the larger of the two, so it does not by itself argue
against fan-out. The finding that matches this repository's work more closely is
that "tool-heavy tasks appear to incur multi-agent overhead"
[cite: scaling-agents-tool-overhead]: editing nix, evaluating, building, and
switching is tool-heavy throughout. The same study reports that "architectures
without centralized verification tend to propagate errors more than those with
centralized coordination" [cite: scaling-agents-centralized-verification], which
is the reason the schema already requires a review subtask in every phase, and
is why this change does not move that responsibility onto the merge node.

## What Changes

- Schema rules in `modules/home/programs/llm/openspec-schema/schema.yaml`:
  - the fake-edge rule, which replaces "order by dependency" with the test that
    an edge exists only when the downstream task reads the upstream task's output
  - the anti-fan-out rule, keyed on write-set intersection: a ready set whose
    declared write sets overlap MUST run in one context
  - a write-set marker per `graph` subtask, naming the paths that subtask may
    modify, which is both the input to that rule and what the existing
    disjoint-file-set instruction hands a worker
  - a `- **MERGE**` marker per `graph` phase, naming the one node that owns the
    merge of the fan-out
  - the two extractor rules an author cannot otherwise know: prose MUST NOT
    repeat a marker label, and a task MUST NOT open with a kind verb
- A rubric in the managed schema at
  `modules/home/programs/llm/openspec-schema/specutil.yaml`, symlinked from
  `openspec/specutil.yaml`, appended to the built-in `spec-driven` preset rather
  than replacing it:
  - `graph-declares-merge`, so a `graph` phase that omits `MERGE` fails the lint
  - an extended `bolded-bullet-lead` allowlist carrying MERGE and TERMINAL
  - a `design-sections` override that drops the adversarial-review section the
    preset requires and the schema fork's design instruction forbids
- `- TERMINAL:` is promoted to `- **TERMINAL**` in the template, which is what
  the allowlist entry is for. The schema note recording that promotion as a TODO
  is deleted only because the promotion happens in the same phase.
- The rest of the adversarial-review section contradiction, which the rubric
  override alone does not reach: `templates/design.md` still emits the section
  labelled REQUIRED, and the `adversarial-review` skill text still tells the
  author to satisfy it.
- One owner keybinding route: the wezterm workspace switcher spawns through
  `s <name>` when its target is a seshy session. `s` is a zsh function, not an
  executable, so the switcher delegates to an interactive zsh rather than
  calling it directly.

### Non-goals

- Agent-initiated panes and editors stay removed. This change adds no slash
  command that spawns a pane, and it does not revisit `dc32e2697`.
- No `zmx` route for agents. The apply instruction already routes a concurrent
  ready set to teammates and fresh-context subagents, none of which opens a
  pane, so there is no gap for a job runner to fill.
- No machine check on write-set intersection. No rule kind specutil ships reads
  an extracted task field, so this is a new rule-kind shape in
  `github:roshbhatia/specutil`, not a new instance of an existing kind. Here the
  rule is stated and the sets are declared, and both are read by a human.
- No check that `MERGE` names a real task. `phase-marker-conditional` tests
  presence only, so an empty or dangling value passes. Same reason, same
  upstream repository.
- No shared-vocabulary work. The defect an earlier draft claimed does not exist:
  `rung` appears nowhere in `modules/home/programs/llm/`, `stage` never denotes
  a phase there, and `applyVocab` substitutes only `{{agent}}` and `{{agents}}`,
  so it cannot make one concept reach two harnesses under two words.
- No rewrite of archived changes. `graph-declares-merge` binds new changes. An
  archived change that is later resumed will fail a lint it never had to pass,
  which is recorded as a risk rather than fixed here.
- No citelock snapshot deduplication. Four records from one page store four
  identical 45 KB snapshots, because citelock names a snapshot after the record
  id. Content-addressing them is a separate change against
  `pkgs/sysinit-agent/internal/citelock/citelock.go`.
- No change to the human-gate rule, to `citelock`, to the review artifact, or to
  the loop markers.

## Behavior

Must do:
- `schema.yaml` states the fake-edge test, decided by `grep -c "reads the" modules/home/programs/llm/openspec-schema/schema.yaml` returning a non-zero count, which returns 0 today
- `schema.yaml` keys the fan-out prohibition on write-set intersection, decided by `grep -c "write sets" modules/home/programs/llm/openspec-schema/schema.yaml` returning a non-zero count, which returns 0 today
- `schema.yaml` states both extractor rules, decided by `grep -c "first match" modules/home/programs/llm/openspec-schema/schema.yaml` returning a non-zero count, which returns 0 today
- the added rubric rules fire on input this change did not author, decided by copying every change under `openspec/changes/archive/` into a scratch active tree and running `specutil check`, which MUST report `graph-declares-merge` on each archived `graph` phase that declares no merge marker, and MUST report zero new `bolded-bullet-lead` findings against the preset
- no artifact in the fork still asks the author for an adversarial-review design section, decided by `grep -rn "Adversarial Review" modules/home/programs/llm/openspec-schema/templates/ modules/home/programs/llm/skills/adversarial-review/` returning nothing
- the template emits the promoted marker, decided by `grep -c -F -- "- **TERMINAL**" modules/home/programs/llm/openspec-schema/templates/tasks.md` returning 1
- the switcher reaches `s`, decided by running `zmx kill` on a scratch session name, opening that workspace from the switcher, then `zmx ls` naming it where it did not before

Must still hold:
- no agent-initiated pane or editor, decided by `grep -rn "wezterm cli spawn\|nvim --server" modules/home/programs/llm/` returning nothing
- `wtrun` stays out of the rendered skill registry, decided by `test ! -f ~/.claude/skills/wtrun/SKILL.md` after a switch
- every active change still passes the rubric, decided by `specutil check` with no argument, which reads every directory under `openspec/changes/` except `archive/`
- both hosts still evaluate, decided by `nix eval --raw .#darwinConfigurations.lv426.system.drvPath` and `nix eval --raw .#nixosConfigurations.arrakis.config.system.build.toplevel.drvPath`
- the lint stays green, decided by `hack/lint.sh --all`

Human-owned decision:
- whether the anti-fan-out rule is drawn in the right place, since a rule that is too strict costs parallelism that was real and no command can measure the counterfactual
- whether the tasks instruction is now too long to be followed, since this change adds five rules to a section that already carries eight and no command can measure whether a rule is read

## Impact

Modified code:
- `modules/home/programs/llm/openspec-schema/schema.yaml`
- `modules/home/programs/llm/openspec-schema/templates/tasks.md`
- `modules/home/programs/llm/openspec-schema/templates/design.md`
- `modules/home/programs/llm/openspec-schema/CHANGES.md`
- `modules/home/programs/llm/openspec-schema/specutil.yaml`
- `modules/home/programs/llm/skills/adversarial-review/SKILL.md`
- `modules/home/programs/llm/skills/adversarial-review/references/adversarial-review-methodology.md`
- `modules/home/programs/wezterm/lua/sysinit/pkg/ui/switcher.lua`
- `openspec/specutil.yaml`, as a symlink into the managed schema

New code: none.

Dependencies: none. `zmx` and `sy` are already on PATH through the existing
modules, and `specutil` is already a flake input.

Prerequisite, landed separately as `992926704`:
`modules/home/programs/llm/runtime/spec-preflight.sh` ran under an inherited
`set -o errexit`, so its schema-drift section aborted the whole report the
moment this change edited the fork, and the pre-commit hook then refused every
commit in the repository.

Impactful and irreversible actions:
- `nh darwin switch`, which replaces the rendered skill directories and the
  wezterm configuration
- `openspec archive`, at the end of the change

Gating signal: `nix build .#darwinConfigurations.lv426.system` must exit 0
before `nh darwin switch`, and `hack/lint.sh --all` must exit 0 before either.
