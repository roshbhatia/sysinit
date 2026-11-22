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
		{UUID: "blocked", Start: "now"},
		{UUID: "review", Start: "now"},
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
		{ID: "dated-new", Task: "dated", CreatedAt: newer, PueueID: &second, Review: true},
		{ID: "accepted", Task: "review", Review: true},
		{ID: "blocked-review", Task: "blocked", Review: true},
	}, []workspace{{ID: "workspace", Task: "review"}}, "test")
	for i, want := range []string{"ready,old-review,preparing,uncertain", "working", "blocked,wait", "dated,review", "backlog"} {
		var got []string
		for _, c := range data.Lanes[i].Cards {
			got = append(got, c.Task.UUID)
		}
		if joined := strings.Join(got, ","); joined != want {
			t.Fatalf("lane %s got %s, want %s", data.Lanes[i].Name, joined, want)
		}
	}
	for i, want := range []string{"late", "preparing"} {
		if got := data.Lanes[0].Cards[i+1].Attempt; got == nil || got.ID != want {
			t.Fatalf("wrong latest attempt: %v, want %s", got, want)
		}
	}
	if data.Lanes[0].Cards[3].Attempt != nil || len(data.Errors) != 1 || !strings.Contains(data.Errors[0], "uncertain") {
		t.Fatalf("ambiguous legacy attempts should be reported: %+v", data)
	}
	if workspaces := data.Lanes[3].Cards[1].Workspaces; len(workspaces) != 1 || workspaces[0].ID != "workspace" {
		t.Fatalf("incorrect workspace association: %v", workspaces)
	}
}
