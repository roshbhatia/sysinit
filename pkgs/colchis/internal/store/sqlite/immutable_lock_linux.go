//go:build linux

package sqlite

import (
	"os"

	"golang.org/x/sys/unix"
)

func acquireImmutableSourceLock(string) (*os.File, bool, error) {
	return nil, false, errReadOnlySnapshotRequired
}

func allocateEmergencyFile(file *os.File, size int64) error {
	if err := unix.Fallocate(int(file.Fd()), 0, 0, size); err != nil {
		return err
	}
	return file.Truncate(size)
}

func publishFileNoReplace(source string, target string) error {
	return unix.Renameat2(unix.AT_FDCWD, source, unix.AT_FDCWD, target, unix.RENAME_NOREPLACE)
}
