// Package cli wires the cobra command tree. Verbs: render, plan, diff, lock,
// graph, check, review, web. No `sync` verb — orchestration of remote writes
// lives in the shipped skills, never in the binary.
package cli

import (
	"crypto/rand"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"runtime"
	"strings"

	"github.com/roshbhatia/specutil/internal/check"
	"github.com/roshbhatia/specutil/internal/detail"
	"github.com/roshbhatia/specutil/internal/graph"
	"github.com/roshbhatia/specutil/internal/ir"
	"github.com/roshbhatia/specutil/internal/registry"
	"github.com/roshbhatia/specutil/internal/render"
	"github.com/roshbhatia/specutil/internal/syncplan"
	"github.com/roshbhatia/specutil/internal/web"
	"github.com/spf13/cobra"
)

// IsNoMapping reports that a `lock get` found no entry. main maps it to exit
// code 3 so callers can distinguish "absent" from other failures.
func IsNoMapping(err error) bool {
	_, ok := err.(errNoMapping)
	return ok
}

// NewRootCmd builds the specutil root command and registers every verb.
func NewRootCmd(version ...string) *cobra.Command {
	v := "dev"
	if len(version) > 0 && version[0] != "" {
		v = version[0]
	}
	root := &cobra.Command{
		Use:     "specutil",
		Short:   "Project OpenSpec change artifacts into other artifacts and visualizations",
		Version: v,
		Long: "specutil parses spec-framework change artifacts (OpenSpec in v1) into a " +
			"normalized IR and projects them into RFCs, design docs, tickets, dependency " +
			"graphs, and visualizations. Remote writes are delegated to an agent via the " +
			"shipped sync skills.",
		SilenceUsage:  true,
		SilenceErrors: false,
	}

	// Global flags inherited by all subcommands.
	root.PersistentFlags().StringP("repo", "C", ".", "repository root containing the openspec/ directory")
	root.PersistentFlags().String("from", "", "input provider: openspec|bmad|plan|stdin|<script-adapter> (default: auto-detect)")

	root.AddCommand(
		newRenderCmd(),
		newPlanCmd(),
		newDiffCmd(),
		newLockCmd(),
		newGraphCmd(),
		newCheckCmd(),
		newNextCmd(),
		newReviewCmd(),
		newWebCmd(),
	)
	return root
}

func newRenderCmd() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "render [change]",
		Short: "Render a change into a shareable document (rfc|design|tickets)",
		Long: "Projects an OpenSpec change into a human-readable document for sharing with\n" +
			"stakeholders. Three output formats are supported:\n\n" +
			"  rfc      — RFC-style proposal doc (Why, What Changes, Requirements)\n" +
			"  design   — Technical design doc (Context, Goals, Decisions, Rollout)\n" +
			"  tickets  — Flat task checklist suitable for copy-paste into a tracker\n\n" +
			"Output goes to stdout by default; use -o to write a file. Combine with\n" +
			"git hooks or CI to auto-generate docs on change commits, or run manually\n" +
			"when preparing a design review or sprint planning session.\n\n" +
			"Typical invocations:\n" +
			"  specutil render --as rfc --change my-change\n" +
			"  specutil render --as tickets -o tickets.md",
		Args: cobra.MaximumNArgs(1),
		RunE: runRender,
	}
	cmd.Flags().String("as", "", "target format: rfc|design|tickets (required)")
	cmd.Flags().String("change", "", "change name to render (or pass as positional arg)")
	cmd.Flags().String("templates", "", "override built-in template directory")
	cmd.Flags().StringP("out", "o", "", "write output to a file instead of stdout")
	return cmd
}

func runRender(cmd *cobra.Command, args []string) error {
	target, _ := cmd.Flags().GetString("as")
	if target == "" {
		return fmt.Errorf("render: --as is required (one of: %v)", render.SupportedTargets())
	}
	change, err := resolveChange(cmd, args)
	if err != nil {
		return err
	}

	overrideDir, _ := cmd.Flags().GetString("templates")
	out, warns, err := render.Render(change, target, render.Options{OverrideDir: overrideDir})
	if err != nil {
		return err
	}
	emitWarnings(cmd, change.Warnings)
	emitWarnings(cmd, warns)

	return writeOut(cmd, out)
}

// resolveChange loads the change named by --change or the first positional arg,
// dispatching to the provider selected by --from (or auto-detected).
func resolveChange(cmd *cobra.Command, args []string) (*ir.Change, error) {
	repo, _ := cmd.Flags().GetString("repo")
	from, _ := cmd.Flags().GetString("from")
	name, _ := cmd.Flags().GetString("change")

	// For path-based providers, the first positional arg is the file path.
	// For openspec, it is the change name. Detect which is which below.
	var pathArg string
	if name == "" && len(args) > 0 {
		// If --from is a path-based provider or looks like a file, treat as path.
		if isPathBased(from) {
			pathArg = args[0]
		} else {
			name = args[0]
		}
	}

	// Enforce --change when using stdin — without it, resolveChange would call
	// p.List() then p.Load() on the same stdin-backed provider, and even with
	// caching the second read's parsed name may differ from what the caller wants.
	if from == "stdin" && name == "" {
		return nil, fmt.Errorf("%s: --change is required when --from stdin", cmd.Name())
	}

	manifest, err := graph.LoadManifest(repo)
	if err != nil {
		fmt.Fprintf(cmd.ErrOrStderr(), "warning: loading specutil.yaml: %v\n", err)
	}
	var providerCfgs []graph.ProviderConfig
	if manifest != nil {
		providerCfgs = manifest.Providers
	}

	p, err := registry.SelectProvider(from, repo, pathArg, providerCfgs)
	if err != nil {
		return nil, err
	}

	if name == "" {
		names, err := p.List()
		if err != nil {
			return nil, err
		}
		switch len(names) {
		case 0:
			return nil, fmt.Errorf("no changes found via provider %q", p.Name())
		case 1:
			name = names[0]
		default:
			return nil, fmt.Errorf("multiple changes found; specify one with --change: %v", names)
		}
	}
	return p.Load(name)
}

// isPathBased reports whether the --from value selects a provider that
// interprets a positional arg as a file path rather than a change name.
func isPathBased(from string) bool {
	switch from {
	case "bmad", "plan", "stdin":
		return true
	}
	return false
}

// emitWarnings prints parse/render warnings to stderr; the binary stays silent
// on stdout so rendered output is clean and pipeable.
func emitWarnings(cmd *cobra.Command, warns []ir.Warning) {
	for _, w := range warns {
		loc := w.File
		if w.Line > 0 {
			loc = fmt.Sprintf("%s:%d", w.File, w.Line)
		}
		if loc != "" {
			fmt.Fprintf(cmd.ErrOrStderr(), "warning: %s: %s\n", loc, w.Msg)
		} else {
			fmt.Fprintf(cmd.ErrOrStderr(), "warning: %s\n", w.Msg)
		}
	}
}

// loadAllChanges uses the registry to load all changes for graph and web.
func loadAllChanges(cmd *cobra.Command) ([]*ir.Change, error) {
	repo, _ := cmd.Flags().GetString("repo")
	from, _ := cmd.Flags().GetString("from")

	manifest, err := graph.LoadManifest(repo)
	if err != nil {
		fmt.Fprintf(cmd.ErrOrStderr(), "warning: loading specutil.yaml: %v\n", err)
	}
	var providerCfgs []graph.ProviderConfig
	if manifest != nil {
		providerCfgs = manifest.Providers
	}

	p, err := registry.SelectProvider(from, repo, "", providerCfgs)
	if err != nil {
		return nil, err
	}
	return p.LoadAll()
}

func newPlanCmd() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "plan [change]",
		Short: "Output a create/update/orphan plan for syncing tasks to an external tracker",
		Long: "Computes what create, update, and orphan operations are needed to reconcile\n" +
			"a change's tasks with an external tracker (Linear, Notion, etc.). The output\n" +
			"is a JSON plan consumed by the sync skills — you rarely invoke this directly.\n\n" +
			"Every operation is ready to write: a reader-facing title, the delivery stage\n" +
			"it belongs to, its sort position, tracker labels, and a rendered Markdown body.\n" +
			"The plan also carries an `overview` body for the container the target groups\n" +
			"tickets under, holding the acceptance criteria once. Source numbering (task\n" +
			"identifiers, phase numbers, spec delta keywords) never appears in that output.\n\n" +
			"How it fits in the workflow:\n" +
			"  1. Edit tasks in tasks.md\n" +
			"  2. specutil plan --target linear --change my-change\n" +
			"  3. A skill reads the plan and performs the actual Linear/Notion API calls\n" +
			"  4. The skill calls `specutil lock set` to record the mapping\n\n" +
			"Invoke manually when debugging sync issues or building custom integrations.",
		Args: cobra.MaximumNArgs(1),
		RunE: runPlan,
	}
	cmd.Flags().String("target", "", "sync target namespace: linear|notion|github-issues (required)")
	cmd.Flags().String("change", "", "change name to plan (or pass as positional arg)")
	cmd.Flags().String("templates", "", "override built-in template directory (ticket.md.tmpl, overview.md.tmpl)")
	cmd.Flags().StringP("out", "o", "", "write output to a file instead of stdout")
	return cmd
}

func runPlan(cmd *cobra.Command, args []string) error {
	target, _ := cmd.Flags().GetString("target")
	if target == "" {
		return fmt.Errorf("plan: --target is required")
	}
	repo, _ := cmd.Flags().GetString("repo")
	change, err := resolveChange(cmd, args)
	if err != nil {
		return err
	}
	emitWarnings(cmd, change.Warnings)
	lock, err := syncplan.LoadLock(repo, change.Name)
	if err != nil {
		return err
	}
	overrideDir, _ := cmd.Flags().GetString("templates")
	plan, err := syncplan.BuildPlanWithOptions(change, lock, target, syncplan.BuildPlanOptions{
		TemplateOverrideDir: overrideDir,
	})
	if err != nil {
		return err
	}
	out, err := json.MarshalIndent(plan, "", "  ")
	if err != nil {
		return err
	}
	return writeOut(cmd, append(out, '\n'))
}

func newDiffCmd() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "diff [change]",
		Short: "Show what has drifted between local tasks and the sync lockfile",
		Long: "Compares the current tasks.md against the per-change lockfile to surface\n" +
			"what has been added, changed, or removed since the last sync. Output is JSON.\n\n" +
			"Use this to audit drift before re-running a sync, or to understand why a\n" +
			"plan would issue create/update operations. Like `plan`, this is normally\n" +
			"called by sync skills rather than directly — but it is useful for debugging\n" +
			"when a task appears to sync-but-not-update.\n\n" +
			"Example:\n" +
			"  specutil diff --target linear --change my-change | jq '.changed'",
		Args: cobra.MaximumNArgs(1),
		RunE: runDiff,
	}
	cmd.Flags().String("target", "", "sync target namespace: linear|notion|github-issues (required)")
	cmd.Flags().String("change", "", "change name to diff (or pass as positional arg)")
	cmd.Flags().StringP("out", "o", "", "write output to a file instead of stdout")
	return cmd
}

func runDiff(cmd *cobra.Command, args []string) error {
	target, _ := cmd.Flags().GetString("target")
	if target == "" {
		return fmt.Errorf("diff: --target is required")
	}
	repo, _ := cmd.Flags().GetString("repo")
	change, err := resolveChange(cmd, args)
	if err != nil {
		return err
	}
	emitWarnings(cmd, change.Warnings)
	lock, err := syncplan.LoadLock(repo, change.Name)
	if err != nil {
		return err
	}
	d := syncplan.DiffChange(change, lock, target)
	out, err := json.MarshalIndent(d, "", "  ")
	if err != nil {
		return err
	}
	return writeOut(cmd, append(out, '\n'))
}

func newLockCmd() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "lock",
		Short: "Read and write the task-to-external-ID mapping used by sync skills",
		Long: "Manages the per-change lockfile that records which local task maps to which\n" +
			"external ticket (Linear issue ID, Notion page ID, etc.).\n\n" +
			"  lock get <identity>                    — read a mapping; exits 3 if absent\n" +
			"  lock set <identity> <external-id>      — write a mapping\n\n" +
			"The lockfile is written by sync skills after they create or update an external\n" +
			"record. You should rarely need to call this directly — use `specutil diff` to\n" +
			"audit the mapping state, and `specutil plan` to preview what a sync would do.\n\n" +
			"When a task is renamed or moved between stages, the identity hash changes and\n" +
			"the old mapping becomes orphaned — `specutil plan` will flag it for deletion.",
	}
	cmd.PersistentFlags().String("target", "", "sync target namespace (e.g. linear|notion)")
	cmd.PersistentFlags().String("change", "", "change owning the lockfile")

	get := &cobra.Command{
		Use:   "get <identity>",
		Short: "Read a lock entry; exits 3 if no mapping exists",
		Args:  cobra.ExactArgs(1),
		RunE:  runLockGet,
	}
	set := &cobra.Command{
		Use:   "set <identity> <external-id>",
		Short: "Write a lock entry",
		Args:  cobra.ExactArgs(2),
		RunE:  runLockSet,
	}
	set.Flags().String("content-hash", "", "content hash to record for drift detection")
	set.Flags().String("title", "", "item title to retain for fuzzy re-match")

	cmd.AddCommand(get, set)
	return cmd
}

// errNoMapping signals `lock get` found no entry; main maps it to exit code 3
// so callers can distinguish "absent" from other failures.
type errNoMapping struct{ identity string }

func (e errNoMapping) Error() string { return fmt.Sprintf("no mapping for identity %q", e.identity) }

func lockChangeName(cmd *cobra.Command) (string, error) {
	name, _ := cmd.Flags().GetString("change")
	if name != "" {
		return name, nil
	}
	from, _ := cmd.Flags().GetString("from")
	// stdin requires --change because lockfile path depends on the change name and
	// consuming stdin just to extract a name would hang on interactive terminals.
	if from == "stdin" {
		return "", fmt.Errorf("lock: --change is required when --from stdin")
	}
	repo, _ := cmd.Flags().GetString("repo")
	manifest, err := graph.LoadManifest(repo)
	if err != nil {
		fmt.Fprintf(cmd.ErrOrStderr(), "warning: loading specutil.yaml: %v\n", err)
	}
	var providerCfgs []graph.ProviderConfig
	if manifest != nil {
		providerCfgs = manifest.Providers
	}
	p, err := registry.SelectProvider(from, repo, "", providerCfgs)
	if err != nil {
		return "", err
	}
	names, err := p.List()
	if err != nil {
		return "", err
	}
	if len(names) == 1 {
		return names[0], nil
	}
	return "", fmt.Errorf("specify --change (found: %v)", names)
}

func runLockGet(cmd *cobra.Command, args []string) error {
	target, _ := cmd.Flags().GetString("target")
	if target == "" {
		return fmt.Errorf("lock get: --target is required")
	}
	repo, _ := cmd.Flags().GetString("repo")
	change, err := lockChangeName(cmd)
	if err != nil {
		return err
	}
	lock, err := syncplan.LoadLock(repo, change)
	if err != nil {
		return err
	}
	ref, ok := lock.Get(target, args[0])
	if !ok {
		return errNoMapping{args[0]}
	}
	fmt.Fprintln(cmd.OutOrStdout(), ref.ExternalID)
	return nil
}

func runLockSet(cmd *cobra.Command, args []string) error {
	target, _ := cmd.Flags().GetString("target")
	if target == "" {
		return fmt.Errorf("lock set: --target is required")
	}
	repo, _ := cmd.Flags().GetString("repo")
	change, err := lockChangeName(cmd)
	if err != nil {
		return err
	}
	lock, err := syncplan.LoadLock(repo, change)
	if err != nil {
		return err
	}
	if args[1] == "" {
		return fmt.Errorf("lock set: external-id must not be empty")
	}
	contentHash, _ := cmd.Flags().GetString("content-hash")
	title, _ := cmd.Flags().GetString("title")
	lock.Set(target, args[0], syncplan.Ref{ExternalID: args[1], ContentHash: contentHash, Title: title})
	return lock.Save(repo, change)
}

func newGraphCmd() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "graph",
		Short: "Output the cross-change dependency graph in various formats",
		Long: "Projects the cross-change dependency DAG into a machine-readable format for\n" +
			"integration with external tools. Primarily used by the skills and CI scripts;\n" +
			"for interactive browsing use `specutil web` instead.\n\n" +
			"Output formats:\n" +
			"  json     — Full graph model (nodes + edges) as JSON [default]\n" +
			"  mermaid  — Mermaid graph definition for embedding in docs or GitHub\n" +
			"  dot      — Graphviz DOT format for rendering with graphviz tools\n" +
			"  detail   — Per-change ticket detail feed (same as DETAIL in web view)\n\n" +
			"The --suggest flag infers candidate edges from shared capabilities without\n" +
			"writing anything. Pair with --harness to use an AI model (claude, gemini,\n" +
			"codex, pi, or any binary on PATH) for deeper semantic analysis.\n\n" +
			"Typical invocations:\n" +
			"  specutil graph --as mermaid                      # insert into a doc or README\n" +
			"  specutil graph --suggest                         # discover implied edges\n" +
			"  specutil graph --suggest --harness claude        # AI-powered discovery\n" +
			"  specutil graph --as json | jq                    # pipe to other tools",
		Args: cobra.NoArgs,
		RunE: runGraph,
	}
	cmd.Flags().String("as", "json", "output format: json|mermaid|dot|detail")
	cmd.Flags().Bool("suggest", false, "infer candidate edges from shared capabilities (read-only)")
	cmd.Flags().String("harness", "", "AI harness for --suggest: claude|gemini|codex|pi|<binary> (default: heuristic only)")
	cmd.Flags().StringP("out", "o", "", "write output to a file instead of stdout")
	return cmd
}

func runGraph(cmd *cobra.Command, args []string) error {
	repo, _ := cmd.Flags().GetString("repo")
	changes, err := loadAllChanges(cmd)
	if err != nil {
		return err
	}
	for _, c := range changes {
		emitWarnings(cmd, c.Warnings)
	}

	if suggest, _ := cmd.Flags().GetBool("suggest"); suggest {
		harness, _ := cmd.Flags().GetString("harness")
		var cands []graph.Candidate
		if harness != "" {
			fmt.Fprintf(cmd.ErrOrStderr(), "running %s harness for dependency suggestions...\n", harness)
			var herr error
			cands, herr = graph.HarnessSuggest(changes, harness)
			if herr != nil {
				return fmt.Errorf("harness suggest: %w", herr)
			}
		} else {
			cands = graph.Suggest(changes)
		}
		if cands == nil {
			cands = []graph.Candidate{}
		}
		out, err := json.MarshalIndent(graph.SuggestReport{Candidates: cands}, "", "  ")
		if err != nil {
			return err
		}
		return writeOut(cmd, append(out, '\n'))
	}

	manifest, err := graph.LoadManifest(repo)
	if err != nil {
		return err
	}
	g, diags := graph.Build(changes, manifest)
	for _, d := range diags {
		fmt.Fprintf(cmd.ErrOrStderr(), "warning: %s: %s\n", d.Kind, d.Msg)
	}

	format, _ := cmd.Flags().GetString("as")
	// The detail feed is the per-change ticket projection the visualizers drill
	// into. It shares graph's loader but is its own renderer-independent schema,
	// so it is dispatched here rather than through Graph.Project.
	if format == "detail" {
		out, err := detail.BuildWith(changes, reviewOptions(repo, changes)).JSON()
		if err != nil {
			return err
		}
		return writeOut(cmd, out)
	}
	out, err := g.Project(format)
	if err != nil {
		return fmt.Errorf("%w (or: detail)", err)
	}
	return writeOut(cmd, out)
}

// writeOut sends bytes to --out if set, otherwise stdout.
func writeOut(cmd *cobra.Command, b []byte) error {
	if outPath, _ := cmd.Flags().GetString("out"); outPath != "" {
		return os.WriteFile(outPath, b, 0o644)
	}
	_, err := cmd.OutOrStdout().Write(b)
	return err
}

func newCheckCmd() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "check [change]",
		Short: "Validate changes against the rubric declared in specutil.yaml",
		Long: "Checks each change against a declared rubric and exits non-zero when any\n" +
			"rule is violated, so it works as a pre-commit hook or a CI gate.\n\n" +
			"Rules are generic and parameterized; the repository supplies the specifics\n" +
			"under `check:` in openspec/specutil.yaml. When that block is absent and\n" +
			"openspec/config.yaml names a schema specutil ships a preset for, that preset\n" +
			"applies automatically. A repository with neither is not checked.\n\n" +
			"Every rule reads only what the author stated: a heading that is present, a\n" +
			"marker that is declared, a bullet that follows another. None infers intent\n" +
			"from prose, so two runs over the same input always agree.\n\n" +
			"Exit codes:\n" +
			"  0  every rule passed (warnings may still be reported)\n" +
			"  1  at least one error-severity rule was violated\n\n" +
			"Typical invocations:\n" +
			"  specutil check                     # every change\n" +
			"  specutil check my-change           # one change\n" +
			"  specutil check --as json | jq      # machine-readable findings\n" +
			"  specutil check --list-rules        # what the resolved rubric enforces",
		Args: cobra.MaximumNArgs(1),
		RunE: runCheck,
	}
	cmd.Flags().String("change", "", "check a single change (or pass as positional arg)")
	cmd.Flags().String("as", "text", "output format: text|json")
	cmd.Flags().Bool("list-rules", false, "list every built-in rule and exit")
	cmd.Flags().StringP("out", "o", "", "write output to a file instead of stdout")
	return cmd
}

func runCheck(cmd *cobra.Command, args []string) error {
	if list, _ := cmd.Flags().GetBool("list-rules"); list {
		var b strings.Builder
		for _, id := range check.RuleIDs() {
			fmt.Fprintf(&b, "%-26s %s\n", id, check.RuleDoc(id))
		}
		return writeOut(cmd, []byte(b.String()))
	}

	repo, _ := cmd.Flags().GetString("repo")
	name, _ := cmd.Flags().GetString("change")

	// A positional argument naming an existing change directory is accepted so
	// this verb is a drop-in for a lint that took a path. The repository root
	// and change name are derived from the standard layout.
	if len(args) > 0 && name == "" {
		if derivedRepo, derivedName, ok := changeDirTarget(args[0]); ok {
			repo, name = derivedRepo, derivedName
			args = nil
			if err := cmd.Flags().Set("repo", repo); err != nil {
				return err
			}
			if err := cmd.Flags().Set("change", name); err != nil {
				return err
			}
		}
	}

	manifest, err := graph.LoadManifest(repo)
	if err != nil {
		return err
	}
	cfg, err := manifest.CheckConfig(repo)
	if err != nil {
		return err
	}
	if cfg.IsZero() {
		fmt.Fprintf(cmd.ErrOrStderr(),
			"no rubric declared: add a `check:` block to %s or name a known schema in openspec/config.yaml\n",
			graph.ManifestFile)
		return nil
	}

	var changes []*ir.Change
	if name != "" || len(args) > 0 {
		c, cerr := resolveChange(cmd, args)
		if cerr != nil {
			return cerr
		}
		changes = []*ir.Change{c}
	} else {
		changes, err = loadAllChanges(cmd)
		if err != nil {
			return err
		}
	}
	for _, c := range changes {
		emitWarnings(cmd, c.Warnings)
	}

	report, err := check.Run(cfg, changes)
	if err != nil {
		return err
	}

	format, _ := cmd.Flags().GetString("as")
	switch format {
	case "json":
		out, merr := json.MarshalIndent(report, "", "  ")
		if merr != nil {
			return merr
		}
		if werr := writeOut(cmd, append(out, '\n')); werr != nil {
			return werr
		}
	case "text":
		if werr := writeOut(cmd, []byte(checkText(report))); werr != nil {
			return werr
		}
	default:
		return fmt.Errorf("unknown check format %q; supported formats: json, text", format)
	}

	if !report.OK() {
		// The findings are already on stdout, so silence cobra's error line and
		// signal the failure through the exit code alone.
		cmd.SilenceErrors = true
		return errCheckFailed
	}
	return nil
}

// changeDirTarget maps a path like <repo>/openspec/changes/<name> to its
// repository root and change name. It reports false for anything that is not a
// change directory in that layout, so the argument falls through to being
// treated as a change name.
func changeDirTarget(arg string) (repo, name string, ok bool) {
	info, err := os.Stat(arg)
	if err != nil || !info.IsDir() {
		return "", "", false
	}
	abs, err := filepath.Abs(arg)
	if err != nil {
		return "", "", false
	}
	abs = filepath.Clean(abs)
	changesDir := filepath.Dir(abs)
	if filepath.Base(changesDir) != "changes" {
		return "", "", false
	}
	openspecDir := filepath.Dir(changesDir)
	if filepath.Base(openspecDir) != "openspec" {
		return "", "", false
	}
	return filepath.Dir(openspecDir), filepath.Base(abs), true
}

// errCheckFailed reports a rubric violation. It reaches main only to set the
// exit code; runCheck silences its printing because the findings are already
// on stdout.
var errCheckFailed = errors.New("check: rubric violated")

// IsCheckFailed reports whether err is the rubric-violation sentinel.
func IsCheckFailed(err error) bool { return errors.Is(err, errCheckFailed) }

// checkText renders a report for a human reader: findings grouped by change,
// then a one-line verdict.
func checkText(r *check.Report) string {
	var b strings.Builder
	change := ""
	for _, f := range r.Findings {
		if f.Change != change {
			change = f.Change
			fmt.Fprintf(&b, "\n%s\n", change)
		}
		loc := f.File
		if f.Line > 0 {
			loc = fmt.Sprintf("%s:%d", f.File, f.Line)
		}
		if loc != "" {
			loc = " (" + loc + ")"
		}
		fmt.Fprintf(&b, "  %-5s %-24s %s%s\n", f.Severity, f.Rule, f.Msg, loc)
	}
	if len(r.Findings) > 0 {
		b.WriteString("\n")
	}
	noun := "changes"
	if len(r.Checked) == 1 {
		noun = "change"
	}
	if r.OK() {
		fmt.Fprintf(&b, "check: passed for %d %s", len(r.Checked), noun)
		if w := r.Warnings(); w > 0 {
			fmt.Fprintf(&b, " (%d warning(s))", w)
		}
		b.WriteString("\n")
		return b.String()
	}
	fmt.Fprintf(&b, "check: failed for %d %s: %d error(s)", len(r.Checked), noun, r.Errors())
	if w := r.Warnings(); w > 0 {
		fmt.Fprintf(&b, ", %d warning(s)", w)
	}
	b.WriteString("\n")
	return b.String()
}

func newWebCmd() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "web",
		Short: "Open a browser view of the change board, dependency graph, and task details",
		Long: "Renders all OpenSpec changes into a self-contained HTML file and opens it\n" +
			"in the default browser. The page has three views:\n\n" +
			"  Kanban  — lifecycle board (proposed / active / archived) with per-change\n" +
			"            progress meters. Click a card to open the detail drilldown.\n\n" +
			"  Graph   — dependency DAG laid out in waves. A wave is the set of changes\n" +
			"            whose prerequisites are all satisfied at the same depth, so every\n" +
			"            change in a wave can be worked in parallel. Node color encodes\n" +
			"            readiness (ready / in progress / blocked / waiting / done).\n\n" +
			"  Detail  — per-change drilldown: execution plan (stages → tasks), Why /\n" +
			"            What Changes narrative, outstanding tasks, and per-stage chart.\n\n" +
			"Every task takes a comment or a removal request, and the Detail view collects\n" +
			"a decision. 'Copy feedback' and 'Download' produce the JSON that\n" +
			"`specutil review ingest` folds back into the change. Nothing is posted: there\n" +
			"is no server behind the page.\n\n" +
			"Pass --diff to review the working-tree code alongside the plan. It runs git\n" +
			"locally, needs --change to say which change the diff belongs to, and defaults\n" +
			"its base to the commit recorded at that change's last review.\n\n" +
			"A fresh file is written to the system temp directory on each invocation so\n" +
			"you always see current data; old files accumulate in /tmp and can be cleared\n" +
			"periodically. Pass -o to write a specific path or '-' for stdout.",
		Args: cobra.NoArgs,
		RunE: runWeb,
	}
	cmd.Flags().StringP("out", "o", "", "output HTML file path (default: timestamped temp file; '-' for stdout)")
	cmd.Flags().Bool("open", true, "open the generated page in the default browser")
	cmd.Flags().Bool("diff", false, "include the working-tree diff for annotation (requires a single change)")
	cmd.Flags().String("change", "", "change the --diff belongs to")
	cmd.Flags().String("base", "", "git ref for --diff (default: the reviewed commit, else HEAD)")
	return cmd
}

func runWeb(cmd *cobra.Command, args []string) error {
	repo, _ := cmd.Flags().GetString("repo")
	changes, err := loadAllChanges(cmd)
	if err != nil {
		return err
	}
	for _, c := range changes {
		emitWarnings(cmd, c.Warnings)
	}
	manifest, err := graph.LoadManifest(repo)
	if err != nil {
		return err
	}
	g, diags := graph.Build(changes, manifest)

	// Build the external-ref map from per-change lockfiles. Missing or unreadable
	// lockfiles are silently skipped — serve never fails over a missing lock.
	refs := make(detail.RefsByKey)
	for _, c := range changes {
		if c.Tasks == nil {
			continue
		}
		lock, lerr := syncplan.LoadLock(repo, c.Name)
		if lerr != nil {
			continue
		}
		for _, p := range c.Tasks.Phases {
			for _, it := range p.Items {
				identity := syncplan.Identity(p.Name, it.Text)
				for target, ns := range lock.Targets {
					if ref, ok := ns[identity]; ok && ref.ExternalID != "" {
						key := c.Name + "\x00" + p.Name + "\x00" + it.Text
						refs[key] = append(refs[key], detail.ExternalRef{
							Target:     target,
							ExternalID: ref.ExternalID,
						})
					}
				}
			}
		}
	}

	opts := reviewOptions(repo, changes)
	opts.Refs = refs
	if err := attachDiff(cmd, repo, changes, &opts); err != nil {
		return err
	}

	html, err := web.Render(g, detail.BuildWith(changes, opts), diags, graph.Suggest(changes))
	if err != nil {
		return err
	}

	outPath, _ := cmd.Flags().GetString("out")
	if outPath == "-" {
		_, err := cmd.OutOrStdout().Write(html)
		return err
	}
	if outPath == "" {
		var b [4]byte
		rand.Read(b[:])
		outPath = filepath.Join(os.TempDir(), "specutil-web-"+hex.EncodeToString(b[:])+".html")
	}
	if err := os.WriteFile(outPath, html, 0o644); err != nil {
		return err
	}
	fmt.Fprintf(cmd.ErrOrStderr(), "wrote %s\n", outPath)

	if open, _ := cmd.Flags().GetBool("open"); open {
		if err := openInBrowser(outPath); err != nil {
			// Non-fatal: the file is written, so degrade to a hint rather than failing.
			fmt.Fprintf(cmd.ErrOrStderr(), "could not open a browser (%v); open %s yourself\n", err, outPath)
		}
	}
	return nil
}

// openInBrowser launches the platform's default handler for path. This shells out
// to a local opener; it performs no network I/O itself (the browser it spawns is
// what later fetches the page's pinned CDN assets), so it stays within the
// binary's determinism boundary.
func openInBrowser(path string) error {
	var bin string
	var args []string
	switch runtime.GOOS {
	case "darwin":
		bin = "open"
	case "windows":
		bin, args = "rundll32", []string{"url.dll,FileProtocolHandler"}
	default:
		bin = "xdg-open"
	}
	return exec.Command(bin, append(args, path)...).Start()
}
