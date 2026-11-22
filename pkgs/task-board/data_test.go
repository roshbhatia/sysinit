package main

import (
	"strings"
	"testing"
)

func TestProjectBoardUsesOwnerStateAndLatestAttempt(t *testing.T) {
	first, second := 1, 2
	data := projectBoard([]task{
		{UUID: "ready", Urgency: 10},
		{UUID: "working", Start: "now"},
		{UUID: "blocked", Start: "now"},
		{UUID: "review", Start: "now"},
		{UUID: "old-review"},
		{UUID: "backlog", LinearState: "backlog"},
		{UUID: "wait", Status: "waiting"},
		{UUID: "idea", Kind: "idea"},
		{UUID: "unassigned", LinearAssigned: "no"},
	}, []task{{UUID: "blocked"}}, []attempt{
		{ID: "late", Task: "old-review", PueueID: &second},
		{ID: "early", Task: "old-review", PueueID: &first, Review: true},
		{ID: "accepted", Task: "review", Review: true},
		{ID: "blocked-review", Task: "blocked", Review: true},
	}, []workspace{{ID: "workspace", Task: "review"}}, "test")
	for i, want := range []string{"ready,old-review", "working", "blocked,wait", "review", "backlog"} {
		var got []string
		for _, c := range data.Lanes[i].Cards {
			got = append(got, c.Task.UUID)
		}
		if joined := strings.Join(got, ","); joined != want {
			t.Fatalf("lane %s got %s, want %s", data.Lanes[i].Name, joined, want)
		}
	}
	if workspaces := data.Lanes[3].Cards[0].Workspaces; len(workspaces) != 1 || workspaces[0].ID != "workspace" {
		t.Fatalf("incorrect workspace association: %v", workspaces)
	}
}
