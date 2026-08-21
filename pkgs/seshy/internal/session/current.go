package session

import (
	"path/filepath"
	"strings"

	"github.com/roshbhatia/sysinit/pkgs/seshy/internal/config"
)

// Containing answers the session whose directory holds dir, if any.
//
// The match is on the path, not on a recorded "active session". A shell, a
// wezterm pane and an editor each know their working directory and nothing else,
// so the working directory is the one signal every caller already has.
func Containing(dir string) (Session, bool) {
	root := config.GetSessionsRoot()
	abs, err := filepath.Abs(dir)
	if err != nil {
		return Session{}, false
	}

	// Try the path as given before resolving links. A repo inside a session can
	// be a symlink to the original checkout, and resolving first would land
	// outside the sessions root and report no session.
	for _, candidate := range dedupe(abs, resolve(abs)) {
		for _, base := range dedupe(root, resolve(root)) {
			if name, ok := nameUnder(base, candidate); ok {
				return byName(name)
			}
		}
	}
	return Session{}, false
}

func resolve(path string) string {
	if found, err := filepath.EvalSymlinks(path); err == nil {
		return found
	}
	return path
}

func dedupe(first, second string) []string {
	if first == second {
		return []string{first}
	}
	return []string{first, second}
}

// nameUnder answers the first path element of dir relative to root, which is the
// session name when dir sits anywhere inside a session.
func nameUnder(root, dir string) (string, bool) {
	rel, err := filepath.Rel(root, dir)
	if err != nil || rel == "." || rel == "" {
		return "", false
	}
	if rel == ".." || strings.HasPrefix(rel, ".."+string(filepath.Separator)) {
		return "", false
	}
	return strings.Split(rel, string(filepath.Separator))[0], true
}

func byName(name string) (Session, bool) {
	sessions, err := List()
	if err != nil {
		return Session{}, false
	}
	for _, found := range sessions {
		if found.Name == name {
			return found, true
		}
	}
	return Session{}, false
}
