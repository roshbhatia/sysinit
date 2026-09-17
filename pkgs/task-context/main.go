package main

import (
	"encoding/json"
	"errors"
	"flag"
	"fmt"
	"net/url"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"runtime"
	"sort"
	"strings"
	"time"
)

type snapshot struct {
	Schema  string          `json:"schema"`
	Created string          `json:"created"`
	Config  string          `json:"config"`
	Tasks   json.RawMessage `json:"tasks"`
}

func taskOutput(binary string, args ...string) ([]byte, error) {
	cmd := exec.Command(binary, append([]string{"rc.context:none", "rc.verbose:nothing", "rc.json.array:on"}, args...)...)
	cmd.Stderr = os.Stderr
	return cmd.Output()
}

func atomicWrite(name string, data []byte) error {
	if err := os.MkdirAll(filepath.Dir(name), 0700); err != nil {
		return err
	}
	f, err := os.CreateTemp(filepath.Dir(name), ".task-context-*")
	if err != nil {
		return err
	}
	defer func() {
		if err := os.Remove(f.Name()); err != nil && !os.IsNotExist(err) {
			fmt.Fprintln(os.Stderr, err)
		}
	}()
	if _, err := f.Write(data); err != nil {
		_ = f.Close()
		return err
	}
	if err := f.Sync(); err != nil {
		_ = f.Close()
		return err
	}
	if err := f.Close(); err != nil {
		return err
	}
	return os.Rename(f.Name(), name)
}

func backup(binary, directory string, keep int) (string, error) {
	if keep < 1 {
		return "", errors.New("retention must be positive")
	}
	data, err := taskOutput(binary, "export")
	if err != nil {
		return "", err
	}
	var tasks []map[string]any
	if err := json.Unmarshal(data, &tasks); err != nil {
		return "", err
	}
	config, err := taskOutput(binary, "_show")
	if err != nil {
		return "", err
	}
	now := time.Now().UTC()
	encoded, err := json.Marshal(snapshot{Schema: "task-context-backup/v1", Created: now.Format(time.RFC3339), Config: string(config), Tasks: data})
	if err != nil {
		return "", err
	}
	name := filepath.Join(directory, "task-"+now.Format("20060102T150405.000000000Z")+".json")
	if err := atomicWrite(name, encoded); err != nil {
		return "", err
	}
	files, err := filepath.Glob(filepath.Join(directory, "task-*.json"))
	if err != nil {
		return "", err
	}
	sort.Strings(files)
	for len(files) > keep {
		old, err := os.ReadFile(files[0])
		if err != nil {
			return "", err
		}
		var existing snapshot
		if json.Unmarshal(old, &existing) != nil || existing.Schema != "task-context-backup/v1" {
			return "", errors.New("refusing to prune an unrecognized backup")
		}
		if err := os.Remove(files[0]); err != nil {
			return "", err
		}
		files = files[1:]
	}
	return name, nil
}

func restore(binary, source, destination string) error {
	raw, err := os.ReadFile(source)
	if err != nil {
		return err
	}
	var s snapshot
	if err := json.Unmarshal(raw, &s); err != nil {
		return err
	}
	var tasks []map[string]any
	if s.Schema != "task-context-backup/v1" || json.Unmarshal(s.Tasks, &tasks) != nil {
		return errors.New("invalid backup")
	}
	absolute, err := filepath.Abs(destination)
	if err != nil {
		return err
	}
	if err := os.Mkdir(absolute, 0700); err != nil {
		return fmt.Errorf("restore requires a new directory: %w", err)
	}
	rc := filepath.Join(absolute, "taskrc")
	settings := []string{}
	for _, line := range strings.Split(s.Config, "\n") {
		key, _, ok := strings.Cut(line, "=")
		if ok && !strings.HasPrefix(key, "sync.") && !strings.HasPrefix(key, "taskd.") && key != "data.location" && key != "hooks.location" && key != "context" {
			settings = append(settings, line)
		}
	}
	settings = append(settings, "data.location="+filepath.Join(absolute, "data"), "hooks=off", "context=", "confirmation=off")
	if err := os.WriteFile(rc, []byte(strings.Join(settings, "\n")+"\n"), 0600); err != nil {
		return err
	}
	cmd := exec.Command(binary, "rc:"+rc, "rc.context:none", "rc.hooks:off", "rc.confirmation:off", "import", "-")
	cmd.Env = append(os.Environ(), "TASKRC="+rc, "TASKDATA="+filepath.Join(absolute, "data"))
	cmd.Stdin = strings.NewReader(string(s.Tasks))
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	return cmd.Run()
}

func openAttribute(binary, field, uuid string, directory bool) error {
	if !regexp.MustCompile(`^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$`).MatchString(uuid) {
		return errors.New("expected a task UUID")
	}
	data, err := taskOutput(binary, uuid, "export")
	if err != nil {
		return err
	}
	var tasks []map[string]any
	if err := json.Unmarshal(data, &tasks); err != nil {
		return err
	}
	if len(tasks) != 1 {
		return errors.New("select exactly one task")
	}
	value, ok := tasks[0][field].(string)
	if !ok || value == "" {
		return fmt.Errorf("task has no %s", field)
	}
	if directory {
		if !filepath.IsAbs(value) {
			return errors.New("repository path must be absolute")
		}
		info, err := os.Stat(value)
		if err != nil {
			return err
		}
		if !info.IsDir() {
			return errors.New("repository path is not a directory")
		}
	} else {
		u, err := url.Parse(value)
		if err != nil || (u.Scheme != "https" && u.Scheme != "http") || u.Hostname() == "" {
			return errors.New("task URL must be HTTP or HTTPS")
		}
	}
	opener := "xdg-open"
	if runtime.GOOS == "darwin" {
		opener = "open"
	}
	cmd := exec.Command(opener, value)
	cmd.Stderr = os.Stderr
	return cmd.Run()
}

func run() error {
	binary := flag.String("task", "taskwarrior", "Taskwarrior executable")
	directory := flag.String("directory", "", "backup directory")
	keep := flag.Int("keep", 14, "backup retention")
	field := flag.String("field", "url", "attribute to open")
	flag.Parse()
	args := flag.Args()
	if len(args) == 0 {
		return errors.New("usage: task-context [options] backup|restore|repo|open-url|open-repo [arguments]")
	}
	switch args[0] {
	case "backup":
		if *directory == "" {
			return errors.New("backup requires --directory")
		}
		name, err := backup(*binary, *directory, *keep)
		if err != nil {
			return err
		}
		fmt.Println(name)
		return nil
	case "restore":
		if len(args) != 3 {
			return errors.New("restore requires SNAPSHOT NEW_DIRECTORY")
		}
		return restore(*binary, args[1], args[2])
	case "open-url", "open-repo":
		if len(args) != 2 {
			return errors.New("open requires one UUID")
		}
		return openAttribute(*binary, *field, args[1], args[0] == "open-repo")
	case "repo":
		root, err := exec.Command("git", "rev-parse", "--show-toplevel").Output()
		if err != nil {
			return err
		}
		report := "focus"
		if len(args) > 1 {
			report = args[1]
		}
		cmd := exec.Command(*binary, "rc.context:none", "repo:"+strings.TrimSpace(string(root)), report)
		cmd.Stdin = os.Stdin
		cmd.Stdout = os.Stdout
		cmd.Stderr = os.Stderr
		return cmd.Run()
	default:
		return errors.New("unknown task-context command")
	}
}
func main() {
	if err := run(); err != nil {
		fmt.Fprintln(os.Stderr, "task-context:", err)
		os.Exit(1)
	}
}
