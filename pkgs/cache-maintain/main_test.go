package main

import (
	"errors"
	"os"
	"path/filepath"
	"testing"
)

func TestPolicyDoesNotCleanBelowLimitOrWithoutApply(t *testing.T) {
	dir := t.TempDir()
	file := filepath.Join(dir, "cached")
	if err := os.WriteFile(file, make([]byte, 8192), 0600); err != nil {
		t.Fatal(err)
	}
	p := policy{Name: "fixture", Directory: dir, MaxBytes: 1, Command: []string{"/unused"}}
	calls := 0
	clean := func(policy) error {
		calls++
		return os.Remove(file)
	}
	if r := maintain(p, false, clean); r.Status != "would-prune" || calls != 0 {
		t.Fatalf("dry run mutated cache: %+v", r)
	}
	p.MaxBytes = 1 << 20
	if r := maintain(p, true, clean); r.Status != "within-limit" || calls != 0 {
		t.Fatalf("small cache was cleaned: %+v", r)
	}
	p.MaxBytes = 1
	if r := maintain(p, true, clean); r.Status != "pruned" || calls != 1 || r.After != 0 {
		t.Fatalf("large cache was not cleaned: %+v", r)
	}
}

func TestSymlinksCannotSelectOtherData(t *testing.T) {
	dir := t.TempDir()
	out := t.TempDir()
	if err := os.WriteFile(filepath.Join(out, "data"), make([]byte, 8192), 0600); err != nil {
		t.Fatal(err)
	}
	link := filepath.Join(dir, "external")
	if err := os.Symlink(out, link); err != nil {
		t.Fatal(err)
	}
	if size, err := allocatedBytes(dir); err != nil || size != 0 {
		t.Fatalf("followed nested symlink: %d %v", size, err)
	}
	if _, err := allocatedBytes(link); err == nil {
		t.Fatal("accepted symlink root")
	}
}

func TestBusyUVDoesNotForceCleanup(t *testing.T) {
	dir := t.TempDir()
	if err := os.WriteFile(filepath.Join(dir, "cached"), make([]byte, 8192), 0600); err != nil {
		t.Fatal(err)
	}
	p := policy{Name: "uv", Directory: dir, MaxBytes: 1, Command: []string{"/unused"}}
	calls := 0
	r := maintain(p, true, func(policy) error {
		calls++
		return errors.New("Timeout (1s) when waiting for lock")
	})
	if r.Status != "busy" || calls != 1 || r.After != r.Before {
		t.Fatalf("unsafe lock handling: %+v", r)
	}
}
