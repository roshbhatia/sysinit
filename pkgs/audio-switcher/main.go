package main

import (
	"bytes"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"os"
	"os/exec"
	"runtime"
	"strconv"
	"strings"
)

type device struct {
	ID      string `json:"id"`
	Name    string `json:"name"`
	Current bool   `json:"current"`
}

type runner func(string, ...string) ([]byte, error)

func command(name string, args ...string) ([]byte, error) {
	cmd := exec.Command(name, args...)
	cmd.Stderr = os.Stderr
	return cmd.Output()
}

func devices(platform string, run runner) ([]device, error) {
	var result []device
	switch platform {
	case "darwin":
		current, err := run("SwitchAudioSource", "-c", "-t", "output", "-f", "json")
		if err != nil {
			return nil, err
		}
		var active struct {
			ID string `json:"id"`
		}
		if err = json.Unmarshal(current, &active); err != nil {
			return nil, err
		}
		data, err := run("SwitchAudioSource", "-a", "-t", "output", "-f", "json")
		if err != nil {
			return nil, err
		}
		decoder := json.NewDecoder(bytes.NewReader(data))
		for {
			var item struct {
				ID   string `json:"id"`
				Name string `json:"name"`
			}
			err = decoder.Decode(&item)
			if errors.Is(err, io.EOF) {
				break
			}
			if err != nil {
				return nil, err
			}
			result = append(result, device{item.ID, item.Name, item.ID == active.ID})
		}
	case "linux":
		current, err := run("pactl", "get-default-sink")
		if err != nil {
			return nil, err
		}
		data, err := run("pactl", "--format=json", "list", "sinks")
		if err != nil {
			return nil, err
		}
		var items []struct {
			Name        string `json:"name"`
			Description string `json:"description"`
		}
		if err = json.Unmarshal(data, &items); err != nil {
			return nil, err
		}
		for _, item := range items {
			result = append(result, device{item.Name, item.Description, item.Name == strings.TrimSpace(string(current))})
		}
	default:
		return nil, fmt.Errorf("unsupported OS: %s", platform)
	}
	if result == nil {
		result = []device{}
	}
	return result, nil
}

func set(platform, id string, items []device, run runner) error {
	for _, item := range items {
		if item.ID == id {
			var err error
			if platform == "darwin" {
				_, err = run("SwitchAudioSource", "-t", "output", "-i", id)
			} else {
				_, err = run("pactl", "set-default-sink", id)
			}
			return err
		}
	}
	return fmt.Errorf("unknown audio device ID: %s", id)
}

func run(args []string) error {
	if len(args) > 0 && (args[0] == "--help" || args[0] == "-h") {
		fmt.Println("audio-switcher [list | set ID]\nNo arguments: select an output with fzf. list emits JSON.")
		return nil
	}
	valid := len(args) == 0 || (len(args) == 1 && args[0] == "list") || (len(args) == 2 && args[0] == "set")
	if !valid {
		return errors.New("usage: audio-switcher [list | set ID]")
	}
	items, err := devices(runtime.GOOS, command)
	if err != nil {
		return err
	}
	if len(args) == 1 {
		return json.NewEncoder(os.Stdout).Encode(items)
	}
	if len(args) == 2 {
		return set(runtime.GOOS, args[1], items, command)
	}
	if len(items) == 0 {
		return errors.New("no audio outputs available")
	}
	var lines strings.Builder
	for i, item := range items {
		name := strings.NewReplacer("\n", " ", "\r", " ", "\t", " ").Replace(item.Name)
		marker := ""
		if item.Current {
			marker = "* "
		}
		fmt.Fprintf(&lines, "%d\t%s%s\n", i, marker, name)
	}
	picker := exec.Command("fzf", "--no-multi", "--delimiter=\t", "--with-nth=2..", "--prompt=Audio output> ")
	picker.Stdin = strings.NewReader(lines.String())
	picker.Stderr = os.Stderr
	selected, err := picker.Output()
	if err != nil {
		var exit *exec.ExitError
		if errors.As(err, &exit) && (exit.ExitCode() == 130 || exit.ExitCode() == 1) {
			return nil
		}
		return err
	}
	index, err := strconv.Atoi(strings.SplitN(strings.TrimSpace(string(selected)), "\t", 2)[0])
	if err != nil || index < 0 || index >= len(items) {
		return errors.New("invalid picker selection")
	}
	return set(runtime.GOOS, items[index].ID, items, command)
}

func main() {
	if err := run(os.Args[1:]); err != nil {
		fmt.Fprintln(os.Stderr, "audio-switcher:", err)
		os.Exit(1)
	}
}
