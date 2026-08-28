//go:build darwin

package sqlite

import (
	"os"

	"golang.org/x/sys/unix"
)

func acquireImmutableSourceLock(path string) (*os.File, bool, error) {
	return nil, false, errReadOnlySnapshotRequired
}

func allocateEmergencyFile(file *os.File, size int64) error {
	allocation := &unix.Fstore_t{
		Flags: unix.F_ALLOCATEALL, Posmode: unix.F_PEOFPOSMODE, Length: size,
	}
	if err := unix.FcntlFstore(file.Fd(), unix.F_PREALLOCATE, allocation); err != nil {
		return err
	}
	return file.Truncate(size)
}

func publishFileNoReplace(source string, target string) error {
	return unix.RenamexNp(source, target, unix.RENAME_EXCL)
}
