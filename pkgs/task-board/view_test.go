package main

import (
	"strings"
	"testing"

	"github.com/charmbracelet/bubbles/textinput"
	"github.com/charmbracelet/bubbles/viewport"
	tea "github.com/charmbracelet/bubbletea"
	"github.com/roshbhatia/go-utils/cell"
)

func TestViewResizesAndScrollsHandoff(t *testing.T) {
	tasks := []task{{UUID: "review", Description: "Review this fixture", Tags: []string{"review"}}}
	tasks[0].Annotations = make([]struct {
		Entry       string `json:"entry"`
		Description string `json:"description"`
	}, 1)
	tasks[0].Annotations[0].Description = strings.Repeat("A long line in the handoff.\n", 30) + "Final answer."
	board := projectBoard(tasks, nil, nil, nil, "local")
	m := model{board: board, column: 3, cursors: make([]int, len(board.Lanes)), input: textinput.New(), notes: viewport.New(80, 20)}

	sizes := []struct{ width, lanes int }{{55, 1}, {100, 2}, {160, 3}, {220, 5}}
	for _, size := range sizes {
		width := size.width
		next, _ := m.Update(tea.WindowSizeMsg{Width: width, Height: 12})
		m = next.(model)
		view := m.View()
		if !strings.Contains(view, "? keys") || !strings.Contains(view, "h/l lanes") {
			t.Fatalf("board help missing at width %d: %s", width, view)
		}
		lanes := strings.Count(view, "(0)") + strings.Count(view, "(1)")
		if lanes != size.lanes || !strings.Contains(view, "Review this fixture") {
			t.Fatalf("unexpected lanes at width %d: %s", width, view)
		}
		for _, line := range strings.Split(view, "\n") {
			if cell.Width(line) > width {
				t.Fatalf("width %d exceeded: %q", width, line)
			}
		}
	}
	next, _ := m.Update(tea.KeyMsg{Type: tea.KeyEnter})
	m = next.(model)
	if !m.detail || strings.Contains(m.View(), "Final answer.") {
		t.Fatal("detail should start at the top")
	}
	for range 10 {
		next, _ = m.Update(tea.KeyMsg{Type: tea.KeyPgDown})
		m = next.(model)
	}
	if !strings.Contains(m.View(), "Final answer.") {
		t.Fatal("all annotation text should be reachable by scrolling")
	}
}

func TestAttemptStatusHidesQueuePayload(t *testing.T) {
	for raw, want := range map[string]string{
		`"Missing"`:                          "Missing",
		`{"Running":{"started_at":"today"}}`: "Running",
		`{"Done":{"result":{"Failed":7}}}`:   "Failed",
	} {
		if got := attemptStatus(&attempt{Result: []byte(raw)}); got != want {
			t.Errorf("attemptStatus(%s) = %q, want %q", raw, got, want)
		}
	}
}

func TestBoardUsesViewportAndWrapsCards(t *testing.T) {
	fixture := task{
		UUID:        "task",
		Description: "Compare the old and new queue output before sharing the final report",
	}
	board := projectBoard([]task{fixture}, nil, nil, nil, "local")
	m := model{
		board: board, width: 132, height: 35,
		cursors: make([]int, len(board.Lanes)), input: textinput.New(),
	}
	lines := strings.Split(m.View(), "\n")
	if len(lines) != m.height || !strings.Contains(lines[len(lines)-1], "? keys") {
		t.Fatalf("expected shortcuts on row %d, got %d rows", m.height, len(lines))
	}
	if !strings.Contains(m.View(), "sharing the final report") {
		t.Fatal("the task description should continue on a second line")
	}
	if cell.Width(lines[2]) != m.width {
		t.Fatalf("lanes should span %d columns: %q", m.width, lines[2])
	}
	for range 12 {
		m.board.Lanes[0].Cards = append(m.board.Lanes[0].Cards, card{Task: fixture})
	}
	m.board.Lanes[0].Cards[12].Task.Description = "Selected card past the first page"
	m.cursors[0] = 12
	if !strings.Contains(m.View(), "Selected card past the first page") {
		t.Fatal("the selected card should remain visible after scrolling")
	}
}
