package cli

import (
	"encoding/json"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"strings"

	"github.com/roshbhatia/specutil/internal/detail"
	"github.com/roshbhatia/specutil/internal/ir"
	"github.com/roshbhatia/specutil/internal/review"
	"github.com/roshbhatia/specutil/internal/vcs"
	"github.com/spf13/cobra"
)

func newReviewCmd() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "review",
		Short: "Record a human verdict on a change and report what moved since",
		Long: "Carries a reviewer's decision back to the agent that wrote the change.\n\n" +
			"  review show    — the standing verdict, open comments, and drift\n" +
			"  review diff    — the working-tree diff since the review, hunk by hunk\n" +
			"  review ingest  — fold an annotation export from `specutil web` into the record\n" +
			"  review set     — record a decision directly, without the browser\n\n" +
			"The record lives at openspec/changes/<name>/specutil.review.yaml and\n" +
			"fingerprints the artifacts it describes. When the artifacts change, the\n" +
			"decision is reported as stale rather than silently continuing to apply, and\n" +
			"each task is classified as new, changed, or unchanged against what was read.\n\n" +
			"Staleness is decided by content hash, never by a timestamp, so the same\n" +
			"inputs always produce the same verdict and a record survives a rebase.\n\n" +
			"The loop:\n" +
			"  1. specutil web                          # annotate tasks, pick a decision\n" +
			"  2. Export from the page (copy or download the JSON)\n" +
			"  3. specutil review ingest feedback.json  # record it, print the brief\n" +
			"  4. The agent reads the brief and revises\n" +
			"  5. specutil review show                  # what drifted since the review",
	}
	cmd.AddCommand(newReviewShowCmd(), newReviewIngestCmd(), newReviewSetCmd(), newReviewDiffCmd())
	return cmd
}

func newReviewDiffCmd() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "diff [change]",
		Short: "Show the working-tree diff since a change was reviewed",
		Long: "Prints what moved in the working tree since the review, so a reviewer sees the\n" +
			"code a change produced and not only the plan that described it.\n\n" +
			"The base defaults to the commit recorded when the decision was taken, so with\n" +
			"no flags this answers \"what did the agent do after I looked at this\". Without a\n" +
			"review record it falls back to HEAD, which shows uncommitted work.\n\n" +
			"Each hunk carries an identity computed from its changed lines, never from line\n" +
			"numbers, so a comment written against a hunk survives edits elsewhere in the\n" +
			"file. That identity is what the browser page writes into an annotation.\n\n" +
			"This reads the local git working tree by running git. It contacts no remote and\n" +
			"reads no credentials. Outside a git working tree it reports an empty diff.\n\n" +
			"Typical invocations:\n" +
			"  specutil review diff my-change                 # since the review\n" +
			"  specutil review diff --base main               # against a branch\n" +
			"  specutil review diff my-change --spec-only     # just the change artifacts\n" +
			"  specutil review diff --as json | jq '.files[].path'",
		Args: cobra.MaximumNArgs(1),
		RunE: runReviewDiff,
	}
	cmd.Flags().String("change", "", "change whose review supplies the base (or pass as positional arg)")
	cmd.Flags().String("base", "", "git ref to compare against (default: the reviewed commit, else HEAD)")
	cmd.Flags().Bool("spec-only", false, "restrict the diff to the change's own artifact directory")
	cmd.Flags().StringSlice("path", nil, "restrict the diff to these paths")
	cmd.Flags().String("as", "text", "output format: text|json")
	cmd.Flags().StringP("out", "o", "", "write output to a file instead of stdout")
	return cmd
}

func runReviewDiff(cmd *cobra.Command, args []string) error {
	repo, _ := cmd.Flags().GetString("repo")
	base, _ := cmd.Flags().GetString("base")
	paths, _ := cmd.Flags().GetStringSlice("path")
	name, _ := cmd.Flags().GetString("change")

	var c *ir.Change
	if name != "" || len(args) > 0 {
		var err error
		if c, err = resolveChange(cmd, args); err != nil {
			return err
		}
	}

	if c != nil {
		if base == "" {
			rec, err := review.LoadRecord(repo, c.Name)
			if err != nil {
				return err
			}
			if rec != nil {
				base = rec.BaseCommit
			}
		}
		if spec, _ := cmd.Flags().GetBool("spec-only"); spec {
			paths = append(paths, filepath.Join("openspec", "changes", c.Name))
		}
	}

	d, err := vcs.Collect(repo, base, paths)
	if err != nil {
		return err
	}

	format, _ := cmd.Flags().GetString("as")
	switch format {
	case "json":
		out, merr := json.MarshalIndent(d, "", "  ")
		if merr != nil {
			return merr
		}
		return writeOut(cmd, append(out, '\n'))
	case "text":
		return writeOut(cmd, []byte(d.Text()))
	default:
		return fmt.Errorf("unknown diff format %q; supported formats: json, text", format)
	}
}

func newReviewShowCmd() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "show [change]",
		Short: "Report the recorded decision, open comments, and drift since review",
		Long: "Prints the standing review verdict for a change, whether it still describes\n" +
			"the current artifacts, which tasks were added or reworded since, and any\n" +
			"comment the reviewer left. With no change named, every change is reported.\n\n" +
			"Exit code is 0 whether or not a decision exists; use `specutil check` with the\n" +
			"review-decision-current rule to gate on it.\n\n" +
			"Typical invocations:\n" +
			"  specutil review show my-change\n" +
			"  specutil review show --as json | jq '.[] | select(.stale)'",
		Args: cobra.MaximumNArgs(1),
		RunE: runReviewShow,
	}
	cmd.Flags().String("change", "", "change to report (or pass as positional arg)")
	cmd.Flags().String("as", "text", "output format: text|json")
	cmd.Flags().StringP("out", "o", "", "write output to a file instead of stdout")
	return cmd
}

func runReviewShow(cmd *cobra.Command, args []string) error {
	repo, _ := cmd.Flags().GetString("repo")
	name, _ := cmd.Flags().GetString("change")

	var changes []*ir.Change
	var err error
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

	statuses := make([]*review.Status, 0, len(changes))
	for _, c := range changes {
		rec, rerr := review.LoadRecord(repo, c.Name)
		if rerr != nil {
			return rerr
		}
		statuses = append(statuses, review.Build(c, rec))
	}

	format, _ := cmd.Flags().GetString("as")
	switch format {
	case "json":
		out, merr := json.MarshalIndent(statuses, "", "  ")
		if merr != nil {
			return merr
		}
		return writeOut(cmd, append(out, '\n'))
	case "text":
		var b strings.Builder
		for i, st := range statuses {
			if i > 0 {
				b.WriteString("\n")
			}
			b.WriteString(review.Markdown(st))
		}
		return writeOut(cmd, []byte(b.String()))
	default:
		return fmt.Errorf("unknown review format %q; supported formats: json, text", format)
	}
}

func newReviewIngestCmd() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "ingest [file]",
		Short: "Fold an annotation export from the web page into the review record",
		Long: "Reads the JSON that `specutil web` exports after a reviewer annotates a\n" +
			"change, writes it to openspec/changes/<name>/specutil.review.yaml, and prints\n" +
			"the brief the agent should act on: requested removals first, then comments,\n" +
			"then anything that drifted.\n\n" +
			"The file argument may be '-' or omitted to read stdin, so a clipboard paste\n" +
			"works directly:\n\n" +
			"  pbpaste | specutil review ingest\n" +
			"  specutil review ingest ~/Downloads/specutil-feedback.json\n" +
			"  specutil review ingest feedback.json --dry-run   # print, write nothing\n\n" +
			"The fingerprints written to the record come from the artifacts on disk now,\n" +
			"not from the export. An author who edited between exporting and ingesting\n" +
			"gets a record reported as stale rather than one that blesses unread text.",
		Args: cobra.MaximumNArgs(1),
		RunE: runReviewIngest,
	}
	cmd.Flags().String("change", "", "override the change named in the feedback document")
	cmd.Flags().Bool("dry-run", false, "print the brief without writing the record")
	cmd.Flags().StringP("out", "o", "", "write output to a file instead of stdout")
	return cmd
}

func runReviewIngest(cmd *cobra.Command, args []string) error {
	repo, _ := cmd.Flags().GetString("repo")

	src, err := readFeedbackSource(cmd, args)
	if err != nil {
		return err
	}
	var fb review.Feedback
	if err := json.Unmarshal(src, &fb); err != nil {
		return fmt.Errorf("parsing feedback: %w", err)
	}
	if err := fb.Validate(); err != nil {
		return fmt.Errorf("feedback: %w", err)
	}

	name, _ := cmd.Flags().GetString("change")
	if name == "" {
		name = fb.Change
	}
	if name == "" {
		return fmt.Errorf("review ingest: the feedback names no change; pass --change")
	}
	if err := cmd.Flags().Set("change", name); err != nil {
		return err
	}

	c, err := resolveChange(cmd, nil)
	if err != nil {
		return err
	}
	emitWarnings(cmd, c.Warnings)

	rec := review.ApplyAt(c, &fb, vcs.HeadCommit(repo))
	if dry, _ := cmd.Flags().GetBool("dry-run"); !dry {
		if err := rec.Save(repo, c.Name); err != nil {
			return err
		}
		fmt.Fprintf(cmd.ErrOrStderr(), "wrote %s\n", review.RecordPath(repo, c.Name))
	}
	return writeOut(cmd, []byte(review.Markdown(review.Build(c, rec))))
}

// readFeedbackSource reads the feedback document from a file argument, or from
// stdin when the argument is absent or "-". Reading stdin is what makes a
// clipboard paste work without a temporary file.
func readFeedbackSource(cmd *cobra.Command, args []string) ([]byte, error) {
	if len(args) == 0 || args[0] == "-" {
		b, err := io.ReadAll(cmd.InOrStdin())
		if err != nil {
			return nil, fmt.Errorf("reading feedback from stdin: %w", err)
		}
		if len(strings.TrimSpace(string(b))) == 0 {
			return nil, fmt.Errorf("review ingest: no feedback on stdin; pass a file path or pipe the export")
		}
		return b, nil
	}
	b, err := os.ReadFile(args[0])
	if err != nil {
		return nil, fmt.Errorf("reading %s: %w", args[0], err)
	}
	return b, nil
}

func newReviewSetCmd() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "set [change]",
		Short: "Record a decision on a change without going through the browser",
		Long: "Writes a review decision straight to the record. Use this when the review\n" +
			"happened somewhere else (a pull request, a meeting) and only the verdict needs\n" +
			"to reach the gate.\n\n" +
			"Accepted decisions: approved, changes-requested, commented.\n\n" +
			"Existing task comments are retained, so approving after addressing feedback\n" +
			"does not erase what was said. Pass --clear-comments to drop them.\n\n" +
			"Typical invocations:\n" +
			"  specutil review set my-change --decision approved\n" +
			"  specutil review set my-change --decision changes-requested --note 'split phase 2'",
		Args: cobra.MaximumNArgs(1),
		RunE: runReviewSet,
	}
	cmd.Flags().String("change", "", "change to record against (or pass as positional arg)")
	cmd.Flags().String("decision", "", "approved|changes-requested|commented (required)")
	cmd.Flags().String("note", "", "note to record with the decision")
	cmd.Flags().Bool("clear-comments", false, "drop the task comments carried in the record")
	cmd.Flags().StringP("out", "o", "", "write output to a file instead of stdout")
	return cmd
}

func runReviewSet(cmd *cobra.Command, args []string) error {
	repo, _ := cmd.Flags().GetString("repo")
	decision := review.Decision(mustString(cmd, "decision"))
	if decision == "" {
		return fmt.Errorf("review set: --decision is required (one of: %s)", decisionList())
	}
	if !decision.Valid() {
		return fmt.Errorf("review set: unknown decision %q; use one of: %s", decision, decisionList())
	}

	c, err := resolveChange(cmd, args)
	if err != nil {
		return err
	}
	emitWarnings(cmd, c.Warnings)

	prev, err := review.LoadRecord(repo, c.Name)
	if err != nil {
		return err
	}
	fb := review.Feedback{
		Schema:   review.Schema,
		Change:   c.Name,
		Decision: decision,
		Note:     mustString(cmd, "note"),
	}
	if clear, _ := cmd.Flags().GetBool("clear-comments"); !clear && prev != nil {
		fb.Annotations = prev.Annotations
	}
	rec := review.ApplyAt(c, &fb, vcs.HeadCommit(repo))
	if err := rec.Save(repo, c.Name); err != nil {
		return err
	}
	fmt.Fprintf(cmd.ErrOrStderr(), "wrote %s\n", review.RecordPath(repo, c.Name))
	return writeOut(cmd, []byte(review.Markdown(review.Build(c, rec))))
}

// reviewOptions assembles the review facts a renderer needs: each task's drift
// against the recorded verdict, the reviewer's standing comments, and the
// verdict itself. An absent or unreadable record is skipped rather than failing
// the render: a visualization must still draw when only some changes have been
// reviewed.
func reviewOptions(repo string, changes []*ir.Change) detail.Options {
	opts := detail.Options{
		Drift:  detail.DriftByKey{},
		Notes:  detail.NotesByKey{},
		Review: detail.ReviewByChange{},
	}
	for _, c := range changes {
		rec, err := review.LoadRecord(repo, c.Name)
		if err != nil || rec == nil {
			continue
		}
		st := review.Build(c, rec)
		opts.Review[c.Name] = detail.ReviewState{
			Decision: string(st.Decision),
			Stale:    st.Stale,
			Note:     st.Note,
		}
		for _, is := range st.Items {
			key := c.Name + "\x00" + is.Identity
			if is.Drift != "" {
				opts.Drift[key] = is.Drift
			}
			if is.Comment != "" || is.Action == review.ActionDrop {
				opts.Notes[key] = detail.Note{Comment: is.Comment, Action: string(is.Action)}
			}
		}
		for _, h := range st.Hunks {
			opts.Notes[c.Name+"\x00"+h.Identity] = detail.Note{
				Comment: h.Comment, Action: string(h.Action),
			}
		}
	}
	return opts
}

// attachDiff collects the working-tree diff for --diff and attaches it to the
// one change it belongs to. Feedback is recorded per change, so a diff shown
// against no particular change could not be ingested; naming the change is
// required rather than guessed, unless there is only one to guess at.
func attachDiff(cmd *cobra.Command, repo string, changes []*ir.Change, opts *detail.Options) error {
	on, _ := cmd.Flags().GetBool("diff")
	if !on {
		return nil
	}
	name, _ := cmd.Flags().GetString("change")
	if name == "" {
		if len(changes) != 1 {
			return fmt.Errorf("web --diff: --change is required when the repository has %d changes", len(changes))
		}
		name = changes[0].Name
	}
	var found bool
	for _, c := range changes {
		if c.Name == name {
			found = true
			break
		}
	}
	if !found {
		return fmt.Errorf("web --diff: no change named %q", name)
	}

	base, _ := cmd.Flags().GetString("base")
	if base == "" {
		rec, err := review.LoadRecord(repo, name)
		if err != nil {
			return err
		}
		if rec != nil {
			base = rec.BaseCommit
		}
	}
	d, err := vcs.Collect(repo, base, nil)
	if err != nil {
		return err
	}
	if d.Note != "" {
		fmt.Fprintf(cmd.ErrOrStderr(), "warning: no diff collected: %s\n", d.Note)
	}
	if opts.Diff == nil {
		opts.Diff = detail.DiffByChange{}
	}
	opts.Diff[name] = d
	return nil
}

func mustString(cmd *cobra.Command, name string) string {
	v, _ := cmd.Flags().GetString(name)
	return v
}

func decisionList() string {
	out := make([]string, 0, len(review.Decisions()))
	for _, d := range review.Decisions() {
		out = append(out, string(d))
	}
	return strings.Join(out, ", ")
}
