package instance

import (
	"context"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"sort"
	"strings"
	"time"

	"github.com/roshbhatia/sysinit/pkgs/colchis/internal/api/socket"
	"github.com/roshbhatia/sysinit/pkgs/colchis/internal/config"
	gitutil "github.com/roshbhatia/sysinit/pkgs/internal/git"
	"github.com/roshbhatia/sysinit/pkgs/internal/paths"
)

const Version = 1

type Record struct {
	Version        int    `json:"version"`
	Key            string `json:"key"`
	Scope          string `json:"scope"`
	StateDirectory string `json:"stateDirectory"`
	Socket         string `json:"socket"`
	Service        string `json:"service,omitempty"`
	Executable     string `json:"executable,omitempty"`
	Automatic      bool   `json:"automatic,omitempty"`
	Stopping       bool   `json:"stopping,omitempty"`
	PID            int    `json:"pid"`
	StartedAt      string `json:"startedAt"`
}

func BaseDirectory() string {
	return filepath.Join(paths.StateHome(), "orca", "w")
}

func Physical(path string) (string, error) {
	absolute, err := filepath.Abs(path)
	if err != nil {
		return "", err
	}
	resolved, err := filepath.EvalSymlinks(absolute)
	if err != nil {
		return "", err
	}
	return filepath.Clean(resolved), nil
}

func DefaultScope(directory string) (string, error) {
	physical, err := Physical(directory)
	if err != nil {
		return "", err
	}
	root, err := gitutil.Root(physical)
	if err != nil {
		return physical, nil
	}
	return Physical(root)
}

func Candidate(scope string) (Record, config.Paths, error) {
	physical, err := Physical(scope)
	if err != nil {
		return Record{}, config.Paths{}, err
	}
	digest := sha256.Sum256([]byte(physical))
	key := hex.EncodeToString(digest[:8])
	stateDirectory := filepath.Join(BaseDirectory(), key)
	resolved, err := config.ResolvePaths(stateDirectory)
	if err != nil {
		return Record{}, config.Paths{}, err
	}
	return Record{
		Version: Version, Key: key, Scope: physical,
		StateDirectory: resolved.StateDirectory, Socket: resolved.Socket,
	}, resolved, nil
}

func Active(directory string) (Record, bool, error) {
	record, found, err := Match(directory)
	if err != nil || !found {
		return record, false, err
	}
	return record, Live(record), nil
}

func Match(directory string) (Record, bool, error) {
	if stateDirectory := os.Getenv("ORCA_STATE_DIR"); stateDirectory != "" {
		resolved, err := config.ResolvePaths(stateDirectory)
		if err != nil {
			return Record{}, false, err
		}
		record, err := Read(filepath.Join(resolved.StateDirectory, "instance.json"))
		if err == nil {
			return record, true, nil
		}
		if !errors.Is(err, os.ErrNotExist) {
			return Record{}, false, err
		}
	}
	physical, err := Physical(directory)
	if err != nil {
		return Record{}, false, err
	}
	records, err := List()
	if err != nil {
		return Record{}, false, err
	}
	for _, record := range records {
		if Contains(record.Scope, physical) {
			return record, true, nil
		}
	}
	return Record{}, false, nil
}

func List() ([]Record, error) {
	entries, err := os.ReadDir(BaseDirectory())
	if errors.Is(err, os.ErrNotExist) {
		return nil, nil
	}
	if err != nil {
		return nil, err
	}
	records := make([]Record, 0, len(entries))
	for _, entry := range entries {
		if !entry.IsDir() {
			continue
		}
		record, err := Read(filepath.Join(BaseDirectory(), entry.Name(), "instance.json"))
		if err == nil {
			records = append(records, record)
		}
	}
	sort.Slice(records, func(first, second int) bool {
		if len(records[first].Scope) != len(records[second].Scope) {
			return len(records[first].Scope) > len(records[second].Scope)
		}
		return records[first].Scope < records[second].Scope
	})
	return records, nil
}

func Read(path string) (Record, error) {
	data, err := os.ReadFile(path)
	if err != nil {
		return Record{}, err
	}
	var record Record
	if err := json.Unmarshal(data, &record); err != nil {
		return Record{}, err
	}
	if record.Version != Version || record.Scope == "" || record.StateDirectory == "" || record.Socket == "" {
		return Record{}, errors.New("instance record is incomplete")
	}
	return record, nil
}

func Write(record Record) error {
	if record.Version != Version || record.StateDirectory == "" {
		return errors.New("instance record is incomplete")
	}
	if err := os.MkdirAll(record.StateDirectory, 0o700); err != nil {
		return err
	}
	data, err := json.Marshal(record)
	if err != nil {
		return err
	}
	temporary, err := os.CreateTemp(record.StateDirectory, ".instance-*.json")
	if err != nil {
		return err
	}
	name := temporary.Name()
	defer os.Remove(name)
	if err := temporary.Chmod(0o600); err != nil {
		_ = temporary.Close()
		return err
	}
	if _, err := temporary.Write(append(data, '\n')); err != nil {
		_ = temporary.Close()
		return err
	}
	if err := temporary.Close(); err != nil {
		return err
	}
	return os.Rename(name, filepath.Join(record.StateDirectory, "instance.json"))
}

func Remove(record Record) error {
	path := filepath.Join(record.StateDirectory, "instance.json")
	current, err := Read(path)
	if errors.Is(err, os.ErrNotExist) {
		return nil
	}
	if err != nil {
		return err
	}
	if current.PID != record.PID {
		return fmt.Errorf("instance record now belongs to process %d", current.PID)
	}
	return os.Remove(path)
}

func Live(record Record) bool {
	info, err := os.Stat(record.Socket)
	if err != nil || info.Mode()&os.ModeSocket == 0 {
		return false
	}
	client, err := socket.NewClient(record.Socket)
	if err != nil {
		return false
	}
	defer client.Close()
	ctx, cancel := context.WithTimeout(context.Background(), 150*time.Millisecond)
	defer cancel()
	_, err = client.Events(ctx, 0, 1)
	return err == nil
}

func Contains(scope string, directory string) bool {
	relative, err := filepath.Rel(scope, directory)
	if err != nil {
		return false
	}
	return relative == "." || (relative != ".." && !strings.HasPrefix(relative, ".."+string(filepath.Separator)))
}

func NewRecord(scope string, service string, automatic bool) (Record, config.Paths, error) {
	record, resolved, err := Candidate(scope)
	if err != nil {
		return Record{}, config.Paths{}, err
	}
	executable, err := os.Executable()
	if err != nil {
		return Record{}, config.Paths{}, err
	}
	executable, err = filepath.EvalSymlinks(executable)
	if err != nil {
		return Record{}, config.Paths{}, err
	}
	record.Service = service
	record.Executable = executable
	record.Automatic = automatic
	record.PID = os.Getpid()
	record.StartedAt = time.Now().UTC().Format(time.RFC3339Nano)
	return record, resolved, nil
}
