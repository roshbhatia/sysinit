package main

import (
	"context"
	"encoding/json"
	"errors"
	"flag"
	"fmt"
	"io/fs"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"syscall"
	"time"
)

type policy struct {
	Name      string            `json:"name"`
	Directory string            `json:"directory"`
	MaxBytes  int64             `json:"max_bytes"`
	Command   []string          `json:"command"`
	Env       map[string]string `json:"env"`
}

type result struct {
	Name   string `json:"name"`
	Before int64  `json:"before_bytes"`
	After  int64  `json:"after_bytes"`
	Status string `json:"status"`
	Error  string `json:"error,omitempty"`
}

type boundedOutput struct {
	text []byte
}

func (b *boundedOutput) Write(p []byte) (int, error) {
	if remaining := 4096 - len(b.text); remaining > 0 {
		b.text = append(b.text, p[:min(len(p), remaining)]...)
	}
	return len(p), nil
}

func allocatedBytes(root string) (int64, error) {
	info, err := os.Lstat(root)
	if errors.Is(err, os.ErrNotExist) {
		return 0, nil
	}
	if err != nil {
		return 0, err
	}
	if !info.IsDir() {
		return 0, errors.New("cache path must be a directory, not a file or symlink")
	}

	var total int64
	seen := make(map[[2]uint64]bool)
	err = filepath.WalkDir(root, func(path string, entry fs.DirEntry, walkErr error) error {
		if errors.Is(walkErr, os.ErrNotExist) {
			return nil
		}
		if walkErr != nil {
			return walkErr
		}
		if !entry.Type().IsRegular() {
			return nil
		}
		info, err := entry.Info()
		if errors.Is(err, os.ErrNotExist) {
			return nil
		}
		if err != nil {
			return err
		}
		stat := info.Sys().(*syscall.Stat_t)
		key := [2]uint64{uint64(stat.Dev), uint64(stat.Ino)}
		if !seen[key] {
			seen[key] = true
			total += stat.Blocks * 512
		}
		return nil
	})
	return total, err
}

func execute(p policy) error {
	ctx, cancel := context.WithTimeout(context.Background(), 3*time.Minute)
	defer cancel()

	command := exec.CommandContext(ctx, p.Command[0], p.Command[1:]...)
	command.Env = os.Environ()
	for key, value := range p.Env {
		command.Env = append(command.Env, key+"="+value)
	}
	var output boundedOutput
	command.Stdout = &output
	command.Stderr = &output
	if err := command.Run(); err != nil {
		return fmt.Errorf("%w: %s", err, strings.TrimSpace(string(output.text)))
	}
	return nil
}

func maintain(p policy, apply bool, run func(policy) error) result {
	r := result{Name: p.Name, Status: "error"}
	if p.Name == "" || !filepath.IsAbs(p.Directory) || p.MaxBytes <= 0 || len(p.Command) == 0 || !filepath.IsAbs(p.Command[0]) {
		r.Error = "invalid cache policy"
		return r
	}
	var err error
	r.Before, err = allocatedBytes(p.Directory)
	if err != nil {
		r.Error = err.Error()
		return r
	}
	r.After = r.Before
	if r.Before <= p.MaxBytes {
		r.Status = "within-limit"
		return r
	}
	if !apply {
		r.Status = "would-prune"
		return r
	}
	if err = run(p); err != nil {
		r.Error = err.Error()
		if p.Name == "uv" && strings.Contains(r.Error, "when waiting for lock") {
			r.Status = "busy"
		}
		return r
	}
	r.After, err = allocatedBytes(p.Directory)
	if err != nil {
		r.Error = err.Error()
		return r
	}
	r.Status = "pruned"
	if r.After > p.MaxBytes {
		r.Status = "retained-by-tool"
	}
	return r
}

func run() error {
	config := flag.String("config", "", "Managed cache policy JSON")
	apply := flag.Bool("apply", false, "Run native cleanup commands above size thresholds")
	report := flag.String("report", "", "Replace the latest JSON report at this path")
	flag.Parse()
	data, err := os.ReadFile(*config)
	if err != nil {
		return err
	}
	var policies []policy
	if err = json.Unmarshal(data, &policies); err != nil {
		return err
	}
	results := make([]result, 0, len(policies))
	failed := false
	for _, p := range policies {
		r := maintain(p, *apply, execute)
		results = append(results, r)
		failed = failed || r.Status == "error"
	}
	data, err = json.MarshalIndent(struct {
		Time    time.Time `json:"time"`
		Results []result  `json:"results"`
	}{time.Now().UTC(), results}, "", "  ")
	if err != nil {
		return err
	}
	if *report != "" {
		if err = os.MkdirAll(filepath.Dir(*report), 0700); err != nil {
			return err
		}
		if err = os.WriteFile(*report+".tmp", data, 0600); err != nil {
			return err
		}
		if err = os.Rename(*report+".tmp", *report); err != nil {
			return err
		}
	}
	if _, err = fmt.Fprintln(os.Stdout, string(data)); err != nil {
		return err
	}
	if failed {
		return errors.New("cache maintenance failed; inspect the report")
	}
	return nil
}

func main() {
	if err := run(); err != nil {
		fmt.Fprintln(os.Stderr, "cache-maintain:", err)
		os.Exit(1)
	}
}
