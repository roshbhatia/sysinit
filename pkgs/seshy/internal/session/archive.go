package session

import (
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"syscall"

	"github.com/roshbhatia/sysinit/pkgs/seshy/internal/config"
)

// ArchivedExists checks if an archived session exists.
func ArchivedExists(name string) bool {
	_, err := os.Stat(filepath.Join(config.GetArchiveRoot(), name))
	return err == nil
}

// GetArchivedPath returns the absolute path to an archived session.
func GetArchivedPath(name string) (string, error) {
	archivePath := filepath.Join(config.GetArchiveRoot(), name)
	if _, err := os.Stat(archivePath); os.IsNotExist(err) {
		return "", fmt.Errorf("archived session '%s' not found", name)
	}
	return archivePath, nil
}

// ListArchived returns all archived sessions.
func ListArchived() ([]Session, error) {
	return listIn(config.GetArchiveRoot())
}

// Archive moves a session out of the sessions root and into the archive root.
// Worktrees, branches, and uncommitted work are all preserved: this is a move,
// not a teardown. Returns the new path.
func Archive(name string) (string, error) {
	sessionPath, err := GetPath(name)
	if err != nil {
		return "", err
	}
	if ArchivedExists(name) {
		return "", fmt.Errorf("session '%s' is already archived", name)
	}
	if err := config.EnsureArchiveRoot(); err != nil {
		return "", fmt.Errorf("failed to create archive directory: %w", err)
	}

	archivePath := filepath.Join(config.GetArchiveRoot(), name)
	if err := moveSession(sessionPath, archivePath); err != nil {
		return "", err
	}
	repairWorktreeRegistrations(archivePath)
	return archivePath, nil
}

// Unarchive moves an archived session back into the sessions root.
// Returns the restored path.
func Unarchive(name string) (string, error) {
	archivePath, err := GetArchivedPath(name)
	if err != nil {
		return "", err
	}
	if Exists(name) {
		return "", fmt.Errorf("session '%s' already exists", name)
	}
	if err := config.EnsureSessionsRoot(); err != nil {
		return "", fmt.Errorf("failed to create sessions directory: %w", err)
	}

	sessionPath := filepath.Join(config.GetSessionsRoot(), name)
	if err := moveSession(archivePath, sessionPath); err != nil {
		return "", err
	}
	repairWorktreeRegistrations(sessionPath)
	return sessionPath, nil
}

// DeleteArchived removes an archived session and cleans up worktrees + branches.
func DeleteArchived(name string, force bool) error {
	archivePath, err := GetArchivedPath(name)
	if err != nil {
		return err
	}
	return deleteAt(archivePath, force)
}

// moveSession renames a session directory. A cross-filesystem archiveDir is the
// one failure the user can act on, so it gets its own message.
func moveSession(src, dst string) error {
	if err := os.Rename(src, dst); err != nil {
		if errors.Is(err, syscall.EXDEV) {
			return fmt.Errorf("cannot move %s to %s: they are on different filesystems — set archiveDir to a path on the same filesystem as sessionsDir", src, dst)
		}
		return fmt.Errorf("failed to move session: %w", err)
	}
	return nil
}
