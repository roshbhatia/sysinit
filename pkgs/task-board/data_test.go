package main

import (
	"strings"
	"testing"
	"time"
)

func TestProjectBoardUsesOwnerStateAndLatestAttempt(t *testing.T) {
	first, second := 90, 1
	older, newer := time.Unix(1, 0), time.Unix(2, 0)
	data := projectBoard([]task{
		{UUID: "ready", Urgency: 10},
		{UUID: "working", Start: "now"},
		{UUID: "blocked", Start: "now", Tags: []string{"review"}},
		{UUID: "review", Start: "now", Tags: []string{"review"}},
		{UUID: "old-review"},
		{UUID: "preparing"},
		{UUID: "uncertain"},
		{UUID: "dated"},
		{UUID: "backlog", LinearState: "backlog"},
		{UUID: "wait", Status: "waiting"},
		{UUID: "idea", Kind: "idea"},
		{UUID: "unassigned", LinearAssigned: "no"},
	}, []task{{UUID: "blocked"}}, []attempt{
		{ID: "late", Task: "old-review", Sequence: 2, PueueID: &second},
		{ID: "early", Task: "old-review", Sequence: 1, PueueID: &first, Review: true},
		{ID: "preparing", Task: "preparing", Sequence: 3},
		{ID: "legacy", Task: "preparing", PueueID: &first, Review: true},
		{ID: "uncertain-a", Task: "uncertain", CreatedAt: older, PueueID: &first, Review: true},
		{ID: "uncertain-b", Task: "uncertain", PueueID: &second},
		{ID: "dated-old", Task: "dated", CreatedAt: older, PueueID: &first},
		{ID: "dated-new", Task: "dated", CreatedAt: newer, PueueID: &second, Review: true, Cwd: "/checkout"},
		{ID: "blocked-review", Task: "blocked", Review: true},
	}, []workspace{{ID: "workspace", Task: "review"}}, "test")
	for i, want := range []string{"ready,dated,old-review,preparing,uncertain", "working", "blocked,wait", "review", "backlog"} {
		var got []string
		for _, c := range data.Lanes[i].Cards {
			got = append(got, c.Task.UUID)
		}
		if joined := strings.Join(got, ","); joined != want {
			t.Fatalf("lane %s got %s, want %s", data.Lanes[i].Name, joined, want)
		}
	}
	for i, want := range []string{"dated-new", "late", "preparing"} {
		if got := data.Lanes[0].Cards[i+1].Attempt; got == nil || got.ID != want {
			t.Fatalf("wrong latest attempt: %v, want %s", got, want)
		}
	}
	if data.Lanes[0].Cards[4].Attempt != nil || len(data.Errors) != 1 || !strings.Contains(data.Errors[0], "uncertain") {
		t.Fatalf("ambiguous legacy attempts should be reported: %+v", data)
	}
	if workspaces := data.Lanes[3].Cards[0].Workspaces; len(workspaces) != 1 || workspaces[0].ID != "workspace" {
		t.Fatalf("incorrect workspace association: %v", workspaces)
	}
}

func TestReviewDirectory(t *testing.T) {
	for _, tc := range []struct {
		name       string
		attempt    *attempt
		workspaces []workspace
		repo, want string
	}{
		{name: "queued checkout", attempt: &attempt{Cwd: "/checkout"}, repo: "/repo", want: "/checkout"},
		{name: "linked workspace", workspaces: []workspace{{Cwd: "/workspace"}}, repo: "/repo", want: "/workspace"},
		{name: "plain directory", repo: "/some folder", want: "/some folder"},
		{name: "missing directory"},
		{name: "relative directory", repo: "relative"},
		{name: "ambiguous workspaces", workspaces: []workspace{{Cwd: "/first"}, {Cwd: "/second"}}, repo: "/repo"},
	} {
		t.Run(tc.name, func(t *testing.T) {
			c := card{Task: task{Repo: tc.repo}, Attempt: tc.attempt, Workspaces: tc.workspaces}
			got, err := c.reviewDirectory()
			if got != tc.want || (err != nil) != (tc.want == "") {
				t.Fatalf("reviewDirectory() = %q, %v; want %q", got, err, tc.want)
			}
		})
	}
}
