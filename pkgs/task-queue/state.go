package main

import (
	"crypto/rand"
	"encoding/json"
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"syscall"
)

type attempt struct {
	ID        string            `json:"id"`
	Task      string            `json:"task,omitempty"`
	Argv      []string          `json:"argv"`
	Cwd       string            `json:"cwd"`
	Env       map[string]string `json:"env"`
	Session   string            `json:"session,omitempty"`
	Group     string            `json:"group"`
	Terminal  string            `json:"terminal,omitempty"`
	PueueID   *int              `json:"pueue_id,omitempty"`
	Result    json.RawMessage   `json:"result"`
	Review    bool              `json:"review"`
	Cancelled bool              `json:"cancel_requested,omitempty"`
}

type job struct {
	ID     int             `json:"id"`
	Label  string          `json:"label"`
	Status json.RawMessage `json:"status"`
}

type task struct {
	UUID    string   `json:"uuid"`
	Status  string   `json:"status"`
	Repo    string   `json:"repo"`
	Tags    []string `json:"tags"`
	Depends []string `json:"depends"`
}

func save(path string, v any) error {
	b, e := json.MarshalIndent(v, "", "  ")
	if e != nil {
		return e
	}
	f, e := os.OpenFile(path+".tmp", os.O_CREATE|os.O_TRUNC|os.O_WRONLY, 0600)
	if e != nil {
		return e
	}
	if _, e = f.Write(b); e == nil {
		e = f.Sync()
	}
	ce := f.Close()
	if e != nil {
		return e
	}
	if ce != nil {
		return ce
	}
	return os.Rename(path+".tmp", path)
}

func read(path string, v any) error {
	b, e := os.ReadFile(path)
	if e != nil {
		return e
	}
	return json.Unmarshal(b, v)
}

func state(raw json.RawMessage) string {
	var s string
	if json.Unmarshal(raw, &s) == nil {
		return s
	}
	var m map[string]json.RawMessage
	if json.Unmarshal(raw, &m) == nil {
		for k := range m {
			return k
		}
	}
	return "Unknown"
}

func success(raw json.RawMessage) bool {
	var v struct {
		Done struct {
			Result json.RawMessage `json:"result"`
		} `json:"Done"`
	}
	return json.Unmarshal(raw, &v) == nil && string(v.Done.Result) == `"Success"`
}

func uuid() string {
	b := make([]byte, 16)
	if _, e := rand.Read(b); e != nil {
		panic(e)
	}
	b[6] = (b[6] & 15) | 64
	b[8] = (b[8] & 63) | 128
	return fmt.Sprintf("%x-%x-%x-%x-%x", b[:4], b[4:6], b[6:8], b[8:10], b[10:])
}

func validID(s string) bool {
	if len(s) != 36 {
		return false
	}
	for i, c := range s {
		if i == 8 || i == 13 || i == 18 || i == 23 {
			if c != '-' {
				return false
			}
		} else if !strings.ContainsRune("0123456789abcdef", c) {
			return false
		}
	}
	return true
}

func recordPath(dir, id string) (string, error) {
	if !validID(id) {
		return "", errors.New("use a full attempt UUID")
	}
	return filepath.Join(dir, id+".json"), nil
}

func lock(path string, nonblock bool) (*os.File, error) {
	f, e := os.OpenFile(path, os.O_CREATE|os.O_RDWR, 0600)
	if e != nil {
		return nil, e
	}
	mode := syscall.LOCK_EX
	if nonblock {
		mode |= syscall.LOCK_NB
	}
	if e = syscall.Flock(int(f.Fd()), mode); e != nil {
		_ = f.Close()
		return nil, e
	}
	return f, nil
}
