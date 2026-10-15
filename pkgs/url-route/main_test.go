package main

import (
	"context"
	"encoding/json"
	"os"
	"path/filepath"
	"strings"
	"testing"

	"github.com/roshbhatia/go-utils/provider"
)

func TestProviderProcess(t *testing.T) {
	for index, arg := range os.Args {
		if arg == "--" && index+1 < len(os.Args) {
			if err := emit(os.Stdin, os.Stdout, os.Args[index+1]); err != nil {
				os.Exit(1)
			}
			os.Exit(0)
		}
	}
}

func TestResolve(t *testing.T) {
	executable, err := os.Executable()
	if err != nil {
		t.Fatal(err)
	}
	directory := t.TempDir()
	manifest := provider.Manifest{
		Version: provider.Version, Name: "devin", Description: "Devin Review",
		Command: []string{executable, "-test.run=TestProviderProcess", "--"},
		Actions: map[string]provider.Action{
			"url.pull": {Description: "Review", Argv: []string{`{"name":"Devin Review","bundle":"org.mozilla.firefox","url":"https://app.devin.ai/review/{{ .Owner }}/{{ .Repo }}/pull/{{ .Number }}"}`}},
		},
	}
	data, err := json.Marshal(manifest)
	if err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(filepath.Join(directory, "devin.json"), data, 0600); err != nil {
		t.Fatal(err)
	}
	rows, err := resolve(context.Background(), directory, "pull", "https://github.com/pinginc/configuration-service/pull/1424", []string{"devin"})
	if err != nil {
		t.Fatal(err)
	}
	if len(rows) != 1 || rows[0].ID != "devin" || rows[0].URL != "https://app.devin.ai/review/pinginc/configuration-service/pull/1424" {
		t.Fatalf("unexpected rows: %+v", rows)
	}
	for _, test := range []struct{ kind, url, name string }{
		{"pull", "https://github.com/pinginc/repo/pull/0", "devin"},
		{"pull", "https://github.com/pinginc/repo/pull/1;touch", "devin"},
		{"pull", "https://github.com.evil/pinginc/repo/pull/1", "devin"},
		{"pull", "https://github.com/pinginc/repo/actions/runs/1", "devin"},
		{"actions", "https://github.com/pinginc/repo/actions/runs/1", "devin"},
		{"pull", "https://github.com/pinginc/repo/pull/1", "missing"},
	} {
		if _, err := resolve(context.Background(), directory, test.kind, test.url, []string{test.name}); err == nil {
			t.Errorf("accepted unsupported route: %+v", test)
		}
	}
}

func TestEmitRejectsInvalidInput(t *testing.T) {
	for _, input := range []string{`{}`, `{"version":"wrong","kind":"request","requestId":"1"}`, `not JSON`} {
		if err := emit(strings.NewReader(input), &strings.Builder{}, `{}`); err == nil {
			t.Errorf("accepted invalid input %q", input)
		}
	}
}
