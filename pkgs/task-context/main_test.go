package main

import (
	"encoding/json"
	"os"
	"os/exec"
	"path/filepath"
	"testing"
)

func TestBackupRestore(t *testing.T) {
	binary, err := exec.LookPath("task")
	if err != nil {
		t.Skip("Taskwarrior supplied by Nix")
	}
	dir := t.TempDir()
	rc := filepath.Join(dir, "taskrc")
	if err := os.WriteFile(rc, []byte("confirmation=off\nnews.version=3.5.0\nuda.repo.type=string\n"), 0600); err != nil {
		t.Fatal(err)
	}
	t.Setenv("TASKRC", rc)
	t.Setenv("TASKDATA", filepath.Join(dir, "data"))
	run := func(args ...string) []byte {
		t.Helper()
		data, err := taskOutput(binary, args...)
		if err != nil {
			t.Fatal(err)
		}
		return data
	}
	run("add", "First", "repo:/some/repo")
	var tasks []map[string]any
	if err := json.Unmarshal(run("export"), &tasks); err != nil {
		t.Fatal(err)
	}
	uuid := tasks[0]["uuid"].(string)
	run(uuid, "annotate", "Keep annotation")
	run("add", "Second", "depends:"+uuid)
	backupDir := filepath.Join(dir, "snapshots")
	first, err := backup(binary, backupDir, 1)
	if err != nil {
		t.Fatal(err)
	}
	second, err := backup(binary, backupDir, 1)
	if err != nil {
		t.Fatal(err)
	}
	if _, err := os.Stat(first); !os.IsNotExist(err) {
		t.Fatal("retention did not remove oldest")
	}
	info, err := os.Stat(second)
	if err != nil || info.Mode().Perm() != 0600 {
		t.Fatal("backup permissions")
	}
	recovered := filepath.Join(dir, "restored")
	if err := restore(binary, second, recovered); err != nil {
		t.Fatal(err)
	}
	if err := restore(binary, second, recovered); err == nil {
		t.Fatal("overwrote existing destination")
	}
	t.Setenv("TASKRC", filepath.Join(recovered, "taskrc"))
	t.Setenv("TASKDATA", filepath.Join(recovered, "data"))
	if err := json.Unmarshal(run("export"), &tasks); err != nil {
		t.Fatal(err)
	}
	if len(tasks) != 2 {
		t.Fatal("missing restored tasks")
	}
	for _, task := range tasks {
		if task["uuid"] == uuid && (task["repo"] != "/some/repo" || task["annotations"] == nil) {
			t.Fatal("lost metadata")
		}
		if task["description"] == "Second" && task["depends"] == nil {
			t.Fatal("lost dependency")
		}
	}
}
