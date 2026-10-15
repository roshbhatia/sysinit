package main

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	neturl "net/url"
	"os"
	"path/filepath"
	"regexp"
	"time"

	"github.com/roshbhatia/go-utils/provider"
)

type target struct {
	ID      string `json:"id"`
	Name    string `json:"name"`
	Detail  string `json:"detail,omitempty"`
	Bundle  string `json:"bundle,omitempty"`
	Command string `json:"command,omitempty"`
	URL     string `json:"url"`
}

var githubURL = regexp.MustCompile(`^https://github\.com/([A-Za-z0-9-]+)/([A-Za-z0-9_.-]+)/(pull|actions/runs)/([1-9][0-9]*)$`)

func resolve(ctx context.Context, directory, kind, url string, names []string) ([]target, error) {
	parts := githubURL.FindStringSubmatch(url)
	if parts == nil || (kind != "pull" && kind != "actions") || (kind == "pull") != (parts[3] == "pull") {
		return nil, errors.New("expected a canonical GitHub URL matching the route kind")
	}
	manifests, err := provider.Discover(directory)
	if err != nil {
		return nil, err
	}
	byName := make(map[string]provider.Manifest)
	for _, loaded := range manifests {
		byName[loaded.Manifest.Name] = loaded.Manifest
	}
	rows := make([]target, 0, len(names))
	input, err := json.Marshal(map[string]string{"url": url, "owner": parts[1], "repo": parts[2], "number": parts[4]})
	if err != nil {
		return nil, err
	}
	for _, name := range names {
		manifest, ok := byName[name]
		if !ok {
			return nil, fmt.Errorf("provider %q is not installed", name)
		}
		invocation, err := provider.Invoke(ctx, manifest, provider.Request{
			RequestID: name, Capability: "url." + kind, Operation: "resolve", Input: input,
		}, provider.InvokeOptions{
			TemplateData: map[string]string{"URL": url, "Owner": parts[1], "Repo": parts[2], "Number": parts[4]},
			Timeout:      2 * time.Second,
		})
		if err != nil {
			return nil, err
		}
		if invocation.Result.Status == provider.ResultDeclined {
			continue
		}
		if invocation.Result.Status != provider.ResultOK {
			return nil, fmt.Errorf("provider %q: %s", name, invocation.Result.Message)
		}
		var row target
		if err := json.Unmarshal(invocation.Result.Output, &row); err != nil {
			return nil, fmt.Errorf("provider %q: %w", name, err)
		}
		if row.Name == "" || row.URL == "" || (row.Bundle == "") == (row.Command == "") {
			return nil, fmt.Errorf("provider %q returned an invalid target", name)
		}
		link, err := neturl.Parse(row.URL)
		if err != nil || link.Host == "" || link.User != nil || (link.Scheme != "https" && link.Scheme != "http") ||
			row.Bundle == "org.hammerspoon.Hammerspoon" || (row.Command != "" && !filepath.IsAbs(row.Command)) {
			return nil, fmt.Errorf("provider %q returned an invalid URL, browser, or command", name)
		}
		row.ID = name
		rows = append(rows, row)
	}
	return rows, nil
}

func emit(input io.Reader, output io.Writer, value string) error {
	var request provider.Request
	if err := json.NewDecoder(io.LimitReader(input, 65536)).Decode(&request); err != nil {
		return err
	}
	if request.Version != provider.Version || request.Kind != provider.FrameRequest || request.RequestID == "" {
		return errors.New("expected a provider/v1 request")
	}
	if !json.Valid([]byte(value)) {
		return errors.New("expected a JSON target")
	}
	return json.NewEncoder(output).Encode(provider.Result{
		Version: provider.Version, Kind: provider.FrameResult, RequestID: request.RequestID,
		Status: provider.ResultOK, Output: json.RawMessage(value),
	})
}

func run(args []string) error {
	if len(args) == 2 && args[0] == "emit" {
		return emit(os.Stdin, os.Stdout, args[1])
	}
	if len(args) < 5 || args[0] != "resolve" {
		return errors.New("usage: url-route resolve DIRECTORY KIND URL PROVIDER [PROVIDER ...]")
	}
	ctx, cancel := context.WithTimeout(context.Background(), 12*time.Second)
	defer cancel()
	rows, err := resolve(ctx, args[1], args[2], args[3], args[4:])
	if err != nil {
		return err
	}
	return json.NewEncoder(os.Stdout).Encode(rows)
}

func main() {
	if err := run(os.Args[1:]); err != nil {
		fmt.Fprintln(os.Stderr, "url-route:", err)
		os.Exit(1)
	}
}
