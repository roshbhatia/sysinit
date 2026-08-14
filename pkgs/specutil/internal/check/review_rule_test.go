package check

import (
	"os"
	"path/filepath"
	"strings"
	"testing"

	"github.com/roshbhatia/specutil/internal/ir"
	"github.com/roshbhatia/specutil/internal/review"
)

func reviewRubric(params map[string]any) Config {
	return Config{Rules: []RuleConfig{{ID: "review-decision-current", Params: params}}}
}

func rooted(t *testing.T) (*ir.Change, string) {
	t.Helper()
	repo := t.TempDir()
	c := good()
	c.Root = filepath.Join(repo, "openspec", "changes", c.Name)
	if err := os.MkdirAll(c.Root, 0o755); err != nil {
		t.Fatalf("mkdir %s: %v", c.Root, err)
	}
	return c, repo
}

func writeRecord(t *testing.T, c *ir.Change, repo string, decision review.Decision) {
	t.Helper()
	rec := review.Apply(c, &review.Feedback{
		Schema: review.Schema, Change: c.Name, Decision: decision,
	})
	if err := rec.Save(repo, c.Name); err != nil {
		t.Fatalf("writing the record: %v", err)
	}
}

func TestReviewRuleFailsWhenNoDecisionIsRecorded(t *testing.T) {
	c, _ := rooted(t)
	rep, err := Run(reviewRubric(nil), []*ir.Change{c})
	if err != nil {
		t.Fatalf("Run: %v", err)
	}
	if rep.OK() {
		t.Fatal("an unreviewed change must not pass the review gate")
	}
	if !strings.Contains(rep.Findings[0].Msg, "no review decision recorded") {
		t.Errorf("unexpected finding: %s", rep.Findings[0].Msg)
	}
}

func TestReviewRuleSkipsUnreviewedChangesWhenRecordIsOptional(t *testing.T) {
	c, _ := rooted(t)
	rep, err := Run(reviewRubric(map[string]any{"requireRecord": false}), []*ir.Change{c})
	if err != nil {
		t.Fatalf("Run: %v", err)
	}
	if !rep.OK() {
		t.Fatalf("requireRecord=false must skip an unreviewed change, got: %+v", rep.Findings)
	}
}

func TestReviewRulePassesAnApprovedCurrentChange(t *testing.T) {
	c, repo := rooted(t)
	writeRecord(t, c, repo, review.DecisionApproved)
	rep, err := Run(reviewRubric(nil), []*ir.Change{c})
	if err != nil {
		t.Fatalf("Run: %v", err)
	}
	if !rep.OK() {
		t.Fatalf("a current approval must pass, got: %+v", rep.Findings)
	}
}

func TestReviewRuleFailsOnAnUnacceptedDecision(t *testing.T) {
	c, repo := rooted(t)
	writeRecord(t, c, repo, review.DecisionChangesRequested)
	rep, err := Run(reviewRubric(nil), []*ir.Change{c})
	if err != nil {
		t.Fatalf("Run: %v", err)
	}
	if rep.OK() {
		t.Fatal("changes-requested must not satisfy a rubric that accepts only approved")
	}
}

func TestReviewRuleFailsWhenTheArtifactsMovedAfterTheDecision(t *testing.T) {
	c, repo := rooted(t)
	writeRecord(t, c, repo, review.DecisionApproved)
	c.Tasks.Phases[0].Items = append(c.Tasks.Phases[0].Items,
		ir.TaskItem{ID: "1.3", Text: "Something nobody reviewed"})

	rep, err := Run(reviewRubric(nil), []*ir.Change{c})
	if err != nil {
		t.Fatalf("Run: %v", err)
	}
	if rep.OK() {
		t.Fatal("an approval must not survive work nobody reviewed being added")
	}
	if !strings.Contains(rep.Findings[0].Msg, "stale") {
		t.Errorf("the finding should name staleness: %s", rep.Findings[0].Msg)
	}
}

func TestReviewRuleAcceptsAWiderDecisionSet(t *testing.T) {
	c, repo := rooted(t)
	writeRecord(t, c, repo, review.DecisionCommented)
	rep, err := Run(reviewRubric(map[string]any{
		"accept": []string{"approved", "commented"},
	}), []*ir.Change{c})
	if err != nil {
		t.Fatalf("Run: %v", err)
	}
	if !rep.OK() {
		t.Fatalf("the rubric accepted commented, got: %+v", rep.Findings)
	}
}
